from decimal import Decimal, InvalidOperation, localcontext
from uuid import UUID

CENT = Decimal('0.01')
ZERO = Decimal('0.00')
MAX_AMOUNT = Decimal('9999999999999999.99')


def money(value: str | Decimal) -> Decimal:
    # No aceptar un float ni siquiera convirtiéndolo después con str().
    if not isinstance(value, (str, Decimal)):
        raise ValueError('Enviar el importe como cadena decimal, por ejemplo "100.00"')
    try:
        amount = Decimal(value)
        if not amount.is_finite() or not ZERO < amount <= MAX_AMOUNT:
            raise ValueError('Importe fuera de DECIMAL(18,2) positivo')
        if amount.as_tuple().exponent < -2:
            raise ValueError('Máximo dos decimales; no se redondea silenciosamente')
        return amount.quantize(CENT)
    except InvalidOperation as exc:
        raise ValueError('Importe decimal inválido') from exc


def split_equal(total: str | Decimal, user_ids: list[UUID]) -> dict[UUID, Decimal]:
    total = money(total)
    if not user_ids or len(user_ids) != len(set(user_ids)):
        raise ValueError('Participantes vacíos o repetidos')
    cents = int(total * 100)
    base, remainder = divmod(cents, len(user_ids))
    if base == 0:
        raise ValueError('Se requiere al menos un centavo por participante')
    # Orden estable: los UUID menores reciben los centavos sobrantes.
    return {uid: Decimal(base + (i < remainder)) / 100
            for i, uid in enumerate(sorted(user_ids, key=str))}


def suggest_transfers(balances: dict[UUID, Decimal]) -> list[dict]:
    with localcontext() as context:
        context.prec = 50  # SUM SQL de DECIMAL(18,2) puede devolver DECIMAL(38,2).
        if any(not isinstance(v, Decimal) or not v.is_finite() or v != v.quantize(CENT)
               for v in balances.values()):
            raise ValueError('Saldo inválido')
        if sum(balances.values(), ZERO) != ZERO:
            raise ValueError('Los saldos no suman cero: revisar integridad de gastos')
        debtors = [[uid, -v] for uid, v in sorted(balances.items(), key=lambda x: str(x[0])) if v < 0]
        creditors = [[uid, v] for uid, v in sorted(balances.items(), key=lambda x: str(x[0])) if v > 0]
        transfers = []
        i = j = 0
        while i < len(debtors) and j < len(creditors):
            amount = min(debtors[i][1], creditors[j][1])
            transfers.append({'from_user_id': debtors[i][0], 'to_user_id': creditors[j][0], 'amount': amount})
            debtors[i][1] -= amount
            creditors[j][1] -= amount
            i += debtors[i][1] == 0
            j += creditors[j][1] == 0
        return transfers  # Liquida saldos; no promete el mínimo global de transferencias.
