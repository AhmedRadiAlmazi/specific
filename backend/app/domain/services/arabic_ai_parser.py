"""
Local Arabic Rule-Based AI Parser Engine — مشروع «مُعين» (Mouin)
Offline-First natural language parser extracting dates, times, money amounts,
debt directions, priority classifications, and proposed item categories from Arabic input.
"""

import re
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, Optional, Tuple
from decimal import Decimal

from backend.app.domain.services.arabic_normalizer import normalize_arabic

class ParsedArabicProposal:
    def __init__(
        self,
        item_type: str,
        title: str,
        due_date: Optional[datetime] = None,
        priority: str = "medium",
        amount: Optional[Decimal] = None,
        currency: str = "YER",
        person_name: Optional[str] = None,
        debt_type: Optional[str] = None,
        reminder_time: Optional[datetime] = None,
        confidence_score: float = 0.85
    ):
        self.item_type = item_type
        self.title = title
        self.due_date = due_date
        self.priority = priority
        self.amount = amount
        self.currency = currency
        self.person_name = person_name
        self.debt_type = debt_type
        self.reminder_time = reminder_time
        self.confidence_score = confidence_score

    def to_dict(self) -> Dict[str, Any]:
        return {
            "item_type": self.item_type,
            "title": self.title,
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "priority": self.priority,
            "amount": str(self.amount) if self.amount is not None else None,
            "currency": self.currency,
            "person_name": self.person_name,
            "debt_type": self.debt_type,
            "reminder_time": self.reminder_time.isoformat() if self.reminder_time else None,
            "confidence_score": self.confidence_score
        }

class ArabicAIParser:
    """Offline natural Arabic text parser extracting structured domain proposals."""

    @classmethod
    def parse(cls, raw_text: str, reference_time: Optional[datetime] = None) -> ParsedArabicProposal:
        now = reference_time or datetime.now(timezone.utc)
        normalized = normalize_arabic(raw_text)

        # 1. Determine Item Type
        item_type = cls._detect_item_type(normalized)

        # 2. Extract Priority
        priority = cls._detect_priority(normalized)

        # 3. Extract Financial Amount & Currency
        amount, currency = cls._extract_money(normalized)

        # 4. Extract Debt Details
        person_name, debt_type = cls._extract_debt_info(normalized)

        # 5. Extract Date and Time
        due_date, reminder_time = cls._extract_datetime(normalized, now)

        clean_title = raw_text.strip()

        return ParsedArabicProposal(
            item_type=item_type,
            title=clean_title,
            due_date=due_date,
            priority=priority,
            amount=amount,
            currency=currency,
            person_name=person_name,
            debt_type=debt_type,
            reminder_time=reminder_time,
            confidence_score=0.90 if amount or due_date else 0.75
        )

    @classmethod
    def _detect_item_type(cls, text: str) -> str:
        if any(w in text for w in ['دين', 'سلف', 'سدد', 'لي عند', 'علي ل', 'مبلغ']):
            return 'debt'
        if any(w in text for w in ['شراء', 'سوق', 'خضار', 'فواكه', 'حليب', 'بقاله', 'سوبرماركت', 'قائمه']):
            return 'shopping'
        if any(w in text for w in ['جواز', 'هويه', 'رخصه', 'عقد', 'وثيقه', 'شهاده', 'فاتوره']):
            return 'document'
        if any(w in text for w in ['ذكرني', 'تنبيه', 'منبه', 'موعد', 'الساعه']):
            return 'reminder'
        if any(w in text for w in ['فكره', 'ملاحظه', 'حساب', 'عنوان', 'رقم']):
            return 'note'
        return 'task'

    @classmethod
    def _detect_priority(cls, text: str) -> str:
        if any(w in text for w in ['عاجل جدا', 'طارئ', 'ضروري جدا', 'قصوي']):
            return 'urgent'
        if any(w in text for w in ['عاجل', 'مهم', 'ضروري', 'هام']):
            return 'high'
        if any(w in text for w in ['غير مهم', 'منخفض', 'وقت لاحق', 'براحتك']):
            return 'low'
        return 'medium'

    @classmethod
    def _extract_money(cls, text: str) -> Tuple[Optional[Decimal], str]:
        currency = 'YER'
        if 'دولار' in text or '$' in text or 'usd' in text:
            currency = 'USD'
        elif 'سعودي' in text or 'sar' in text:
            currency = 'SAR'

        match = re.search(r'(\d+(?:\.\d+)?)', text)
        if match:
            try:
                return Decimal(match.group(1)), currency
            except Exception:
                pass

        return None, currency

    @classmethod
    def _extract_debt_info(cls, text: str) -> Tuple[Optional[str], Optional[str]]:
        debt_type = 'payable'
        person_name = None

        if 'لي عند' in text or ('سلفته' in text or 'يطالب' in text and 'يطالبني' not in text):
            debt_type = 'receivable'
        elif 'علي ل' in text or 'استلفت' in text or 'مدين' in text:
            debt_type = 'payable'

        # Extract name after common prepositions or attached Lam prefix
        words = text.split()
        for w in words:
            if w.startswith('ل') and len(w) > 2:
                stem = w[1:]
                if stem not in ['شراء', 'دفع', 'سداد', 'تذكير', 'غدا', 'اليوم', 'مواد', 'المواد', 'المستشفي', 'العمل']:
                    person_name = stem
                    break
            elif w in ['من', 'عند', 'مع']:
                idx = words.index(w)
                if idx + 1 < len(words):
                    candidate = words[idx + 1]
                    if candidate not in ['شراء', 'دفع', 'سداد', 'تذكير', 'غدا', 'اليوم']:
                        person_name = candidate
                        break

        return person_name, debt_type

    @classmethod
    def _extract_datetime(cls, text: str, now: datetime) -> Tuple[Optional[datetime], Optional[datetime]]:
        due_date: Optional[datetime] = None
        hour = 9
        minute = 0

        time_match = re.search(r'الساعه\s+(\d{1,2})(?::(\d{2}))?\s*(صباحا|مساء|ص|م)?', text)
        if time_match:
            h = int(time_match.group(1))
            m = int(time_match.group(2)) if time_match.group(2) else 0
            period = time_match.group(3)
            if period in ['مساء', 'م'] and h < 12:
                h += 12
            elif period in ['صباحا', 'ص'] and h == 12:
                h = 0
            hour = h
            minute = m

        if 'غدا' in text or 'بكره' in text:
            target = now + timedelta(days=1)
            due_date = target.replace(hour=hour, minute=minute, second=0, microsecond=0)
        elif 'بعد غد' in text:
            target = now + timedelta(days=2)
            due_date = target.replace(hour=hour, minute=minute, second=0, microsecond=0)
        elif 'اليوم' in text:
            due_date = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
        elif 'بعد ساعتين' in text:
            due_date = now + timedelta(hours=2)
        elif 'بعد ساعه' in text:
            due_date = now + timedelta(hours=1)
        elif 'نهايه الشهر' in text:
            due_date = (now + timedelta(days=30)).replace(hour=hour, minute=minute, second=0, microsecond=0)

        reminder_time = due_date
        return due_date, reminder_time
