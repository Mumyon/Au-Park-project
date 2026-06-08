FREE_MINUTES = 30
BASE_PERIOD_MINUTES = 30
BASE_FEE = 1500
EXTRA_UNIT_MINUTES = 10
EXTRA_UNIT_FEE = 500
DAILY_MAX_FEE = 15000
MINUTES_PER_DAY = 24 * 60


def calculate_parking_fee(duration_minutes: int) -> int:
    return calculate_parking_fee_breakdown(duration_minutes)["total_fee"]


def calculate_parking_fee_breakdown(duration_minutes: int) -> dict[str, int]:
    minutes = max(0, duration_minutes)
    full_days, remaining_minutes = divmod(minutes, MINUTES_PER_DAY)
    daily_fee = _calculate_daily_fee(remaining_minutes)
    base_fee = full_days * BASE_FEE
    if daily_fee > 0:
        base_fee += BASE_FEE
    total_fee = full_days * DAILY_MAX_FEE + daily_fee
    return {
        "base_fee": base_fee,
        "additional_fee": max(0, total_fee - base_fee),
        "total_fee": total_fee,
    }


def _calculate_daily_fee(duration_minutes: int) -> int:
    if duration_minutes <= FREE_MINUTES:
        return 0
    if duration_minutes <= FREE_MINUTES + BASE_PERIOD_MINUTES:
        return BASE_FEE

    extra_minutes = duration_minutes - FREE_MINUTES - BASE_PERIOD_MINUTES
    extra_units = (extra_minutes + EXTRA_UNIT_MINUTES - 1) // EXTRA_UNIT_MINUTES
    return min(DAILY_MAX_FEE, BASE_FEE + extra_units * EXTRA_UNIT_FEE)
