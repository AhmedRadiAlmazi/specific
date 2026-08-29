"""
Reminder Occurrence Domain Service — مشروع «مُعين» (Mouin)
Computes upcoming deterministic instances for recurrence rules without framework dependencies.
"""

from datetime import datetime, timezone, timedelta
from typing import List
from backend.app.domain.entities.reminder import ReminderRule, ReminderInstance
from backend.app.domain.value_objects.identity import EntityId
from backend.app.domain.value_objects.types import ReminderTriggerType

class ReminderOccurrenceService:
    @staticmethod
    def generate_next_occurrences(rule: ReminderRule, count: int = 5) -> List[ReminderInstance]:
        """Generates deterministic upcoming occurrences for a rule."""
        if not rule.is_active or rule.is_deleted():
            return []
        
        results: List[ReminderInstance] = []
        if rule.trigger_type == ReminderTriggerType.ABSOLUTE and rule.trigger_time:
            if not any(inst.scheduled_time == rule.trigger_time for inst in rule.instances):
                inst = rule.generate_instance(EntityId.new(), rule.trigger_time)
                results.append(inst)
        elif rule.trigger_type == ReminderTriggerType.RECURRING:
            base_time = rule.trigger_time or datetime.now(timezone.utc)
            for i in range(count):
                sched = base_time + timedelta(days=i + 1)
                try:
                    inst = rule.generate_instance(EntityId.new(), sched)
                    results.append(inst)
                except Exception:
                    continue  # Already exists
        return results
