from decimal import Decimal
from uuid import UUID

import pytest
from pydantic import ValidationError
from sqlalchemy.dialects import mssql
from sqlalchemy.schema import CreateTable

from app.core.database_settings import DatabaseSettings
from app.domains.finances.db_models import Base, Expense, ExpenseParticipant
from app.domains.finances.db_schemas import BalanceOutput, ExpenseInput
from app.domains.finances.exact_money import money, split_equal, suggest_transfers

A, B, C = (UUID(int=i) for i in (1, 2, 3))


@pytest.mark.parametrize('value', [0.1, 100, True, 'NaN', 'Infinity', '-1.00', '0.00',
                                 '1.001', '10000000000000000.00'])
def test_reject_invalid_money(value):
    with pytest.raises(ValueError):
        money(value)


def test_maximum_decimal_is_exact():
    assert money('9999999999999999.99') == Decimal('9999999999999999.99')


def test_cent_remainder_is_stable():
    shares = split_equal('100.00', [C, B, A])
    assert shares == {A: Decimal('33.34'), B: Decimal('33.33'), C: Decimal('33.33')}
    assert sum(shares.values()) == Decimal('100.00')


def payload():
    return dict(squad_id=A, client_request_id=UUID(int=99), paid_by_user_id=A,
                description='Transporte', amount='100.00',
                participants=[{'user_id': A, 'share_amount': '33.34'},
                              {'user_id': B, 'share_amount': '33.33'},
                              {'user_id': C, 'share_amount': '33.33'}])


def test_shares_must_match_without_rounding():
    value = payload()
    value['participants'][0]['share_amount'] = '33.33'
    with pytest.raises(ValidationError):
        ExpenseInput(**value)


def test_duplicate_participants():
    value = payload()
    value['participants'][1]['user_id'] = A
    with pytest.raises(ValidationError):
        ExpenseInput(**value)


def test_json_money_stays_string():
    result = ExpenseInput(**payload())
    assert result.model_dump(mode='json')['amount'] == '100.00'
    assert result.participants[0].share_amount == Decimal('33.34')


def test_transfers_clear_all_balances():
    balances = {A: Decimal('66.66'), B: Decimal('-33.33'), C: Decimal('-33.33')}
    transfers = suggest_transfers(balances)
    remaining = balances.copy()
    for t in transfers:
        remaining[t['from_user_id']] += t['amount']
        remaining[t['to_user_id']] -= t['amount']
    assert all(v == Decimal('0.00') for v in remaining.values())
    out = BalanceOutput(squad_id=A, net_balances=balances, suggested_transfers=transfers)
    assert out.model_dump(mode='json')['net_balances'][str(A)] == '66.66'


def test_unbalanced_ledger_is_rejected():
    with pytest.raises(ValueError):
        suggest_transfers({A: Decimal('0.01')})


def test_ddl_is_sql_server_decimal():
    for table in Base.metadata.sorted_tables:
        assert str(CreateTable(table).compile(dialect=mssql.dialect()))
    for model, column in [(Expense, 'amount'), (ExpenseParticipant, 'share_amount')]:
        ddl = str(CreateTable(model.__table__).compile(dialect=mssql.dialect()))
        assert 'DECIMAL(18, 2)' in ddl
        assert model.__table__.c[column].type.asdecimal
    expense_ddl = str(CreateTable(Expense.__table__).compile(dialect=mssql.dialect()))
    assert 'client_request_id UNIQUEIDENTIFIER NOT NULL' in expense_ddl


def test_production_requires_certificate_validation():
    with pytest.raises(ValidationError):
        DatabaseSettings(_env_file=None, environment='production', db_user='test',
                         db_password='test', db_trust_server_certificate=True)


def test_credentials_are_not_interpolated_into_url():
    settings = DatabaseSettings(_env_file=None, db_user='test', db_password='a@b:c;d')
    url = settings.connection_url()
    assert url.password == 'a@b:c;d'
    assert url.query['Encrypt'] == 'yes'
    assert url.query['TrustServerCertificate'] == 'no'
