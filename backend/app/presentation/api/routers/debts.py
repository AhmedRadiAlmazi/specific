"""
Debts & Financial Ledger Router — مشروع «مُعين» (Mouin)
Strict Decimal precision and append-only ledger transactions.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from backend.app.presentation.api.dependencies.workspace import get_active_workspace
from backend.app.presentation.api.dependencies.container import (
    get_debt_repo, get_debt_handler, SqliteDebtRepository, DebtCommandHandler
)
from backend.app.presentation.api.schemas.debt_dto import (
    CreateDebtRequest, RecordPaymentRequest, ReversePaymentRequest, DebtResponseDTO, DebtTransactionDTO
)
from backend.app.application.commands.debt_commands import (
    CreateDebtCommand, RecordDebtPaymentCommand, ReverseDebtTransactionCommand
)
from backend.app.domain.value_objects.identity import WorkspaceId, EntityId

router = APIRouter(prefix="/api/v1/workspaces/{workspace_id}/debts", tags=["Debts & Financials"])

def _to_debt_dto(debt) -> DebtResponseDTO:
    tx_dtos = [
        DebtTransactionDTO(
            id=str(tx.id),
            transaction_type=tx.transaction_type.value,
            amount=tx.amount.amount,
            currency=str(tx.amount.currency),
            transaction_date=tx.transaction_date,
            notes=tx.notes,
            reference_transaction_id=str(tx.reference_transaction_id) if tx.reference_transaction_id else None,
            created_at=tx.created_at
        )
        for tx in debt.transactions
    ]
    return DebtResponseDTO(
        id=str(debt.id),
        workspace_id=str(debt.workspace_id),
        debt_type=debt.debt_type.value,
        person_id=str(debt.person_id),
        total_amount=debt.total_amount.amount,
        currency=str(debt.total_amount.currency),
        remaining_amount=debt.calculate_remaining_amount().amount,
        status=debt.status.value,
        due_date=debt.due_date,
        transactions=tx_dtos
    )

@router.get("", response_model=List[DebtResponseDTO])
def list_debts(
    workspace_id: str = Depends(get_active_workspace),
    repo: SqliteDebtRepository = Depends(get_debt_repo)
):
    debts = repo.list_by_workspace(WorkspaceId(workspace_id))
    return [_to_debt_dto(d) for d in debts if d]

@router.post("", response_model=DebtResponseDTO, status_code=status.HTTP_201_CREATED)
def create_debt(
    payload: CreateDebtRequest,
    workspace_id: str = Depends(get_active_workspace),
    handler: DebtCommandHandler = Depends(get_debt_handler),
    repo: SqliteDebtRepository = Depends(get_debt_repo)
):
    cmd = CreateDebtCommand(
        workspace_id=workspace_id,
        person_id=payload.person_id,
        debt_type=payload.debt_type.value,
        total_amount=str(payload.total_amount),
        currency=payload.currency,
        due_date=payload.due_date
    )
    debt_id = handler.handle_create(cmd)
    debt = repo.get_by_id(WorkspaceId(workspace_id), EntityId(debt_id))
    return _to_debt_dto(debt)

@router.get("/{debt_id}", response_model=DebtResponseDTO)
def get_debt(
    debt_id: str,
    workspace_id: str = Depends(get_active_workspace),
    repo: SqliteDebtRepository = Depends(get_debt_repo)
):
    debt = repo.get_by_id(WorkspaceId(workspace_id), EntityId(debt_id))
    if not debt or debt.is_deleted():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Debt {debt_id} not found.")
    return _to_debt_dto(debt)

@router.post("/{debt_id}/transactions", response_model=DebtResponseDTO)
def record_payment(
    debt_id: str,
    payload: RecordPaymentRequest,
    workspace_id: str = Depends(get_active_workspace),
    handler: DebtCommandHandler = Depends(get_debt_handler),
    repo: SqliteDebtRepository = Depends(get_debt_repo)
):
    cmd = RecordDebtPaymentCommand(
        workspace_id=workspace_id,
        debt_id=debt_id,
        amount=str(payload.amount),
        currency=payload.currency,
        transaction_date=payload.transaction_date,
        notes=payload.notes
    )
    handler.handle_record_payment(cmd)
    debt = repo.get_by_id(WorkspaceId(workspace_id), EntityId(debt_id))
    return _to_debt_dto(debt)

@router.post("/{debt_id}/transactions/reverse", response_model=DebtResponseDTO)
def reverse_payment(
    debt_id: str,
    payload: ReversePaymentRequest,
    workspace_id: str = Depends(get_active_workspace),
    handler: DebtCommandHandler = Depends(get_debt_handler),
    repo: SqliteDebtRepository = Depends(get_debt_repo)
):
    cmd = ReverseDebtTransactionCommand(
        workspace_id=workspace_id,
        debt_id=debt_id,
        target_tx_id=payload.target_tx_id,
        notes=payload.notes
    )
    handler.handle_reverse(cmd)
    debt = repo.get_by_id(WorkspaceId(workspace_id), EntityId(debt_id))
    return _to_debt_dto(debt)
