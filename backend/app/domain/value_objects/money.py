"""
Money & Currency Value Objects — مشروع «مُعين» (Mouin)
Strictly based on Python Decimal (never float) with exact precision.
"""

from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from backend.app.domain.exceptions import InvariantViolationError, CurrencyMismatchError

@dataclass(frozen=True)
class Currency:
    code: str

    def __post_init__(self):
        if not self.code or len(self.code.strip()) != 3:
            raise InvariantViolationError("Currency code must be a 3-letter uppercase string (e.g. 'YER', 'USD', 'SAR').")
        object.__setattr__(self, "code", self.code.strip().upper())

    def __str__(self) -> str:
        return self.code

# Standard default currencies
YER = Currency("YER")
USD = Currency("USD")
SAR = Currency("SAR")

@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: Currency = YER

    def __post_init__(self):
        if not isinstance(self.amount, Decimal):
            if isinstance(self.amount, (int, str)):
                object.__setattr__(self, "amount", Decimal(str(self.amount)))
            else:
                raise InvariantViolationError(f"Money amount must be Decimal, integer, or numeric string. Float is strictly prohibited. Got {type(self.amount)}")
        # Quantize to 2 decimal places
        quantized = self.amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        object.__setattr__(self, "amount", quantized)

    @classmethod
    def from_str(cls, amount_str: str, currency_code: str = "YER") -> "Money":
        return cls(amount=Decimal(amount_str), currency=Currency(currency_code))

    def add(self, other: "Money") -> "Money":
        self._assert_same_currency(other)
        return Money(self.amount + other.amount, self.currency)

    def subtract(self, other: "Money") -> "Money":
        self._assert_same_currency(other)
        return Money(self.amount - other.amount, self.currency)

    def is_positive(self) -> bool:
        return self.amount > Decimal("0.00")

    def is_zero(self) -> bool:
        return self.amount == Decimal("0.00")

    def _assert_same_currency(self, other: "Money"):
        if not isinstance(other, Money) or self.currency != other.currency:
            raise CurrencyMismatchError(f"Cannot operate on Money with different currencies: {self.currency} vs {getattr(other, 'currency', None)}")

    def __add__(self, other: "Money") -> "Money":
        return self.add(other)

    def __sub__(self, other: "Money") -> "Money":
        return self.subtract(other)

    def __str__(self) -> str:
        return f"{self.amount} {self.currency}"
