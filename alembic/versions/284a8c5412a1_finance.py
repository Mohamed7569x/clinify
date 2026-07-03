"""finance

Revision ID: 284a8c5412a1
Revises: 92e0ade093fd
Create Date: 2026-04-10 23:20:13.902338

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = '284a8c5412a1'
down_revision: Union[str, None] = '92e0ade093fd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("""
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ledgerentrytype') THEN
            CREATE TYPE ledgerentrytype AS ENUM (
                'PATIENT_PAYMENT',
                'PAYMENT_ADJUSTMENT',
                'REFUND',
                'WAIVER',
                'RENT',
                'SALARY',
                'UTILITIES',
                'SUPPLIES',
                'MAINTENANCE',
                'MARKETING',
                'TAX',
                'OTHER_EXPENSE',
                'OWNER_DRAW',
                'OTHER_INCOME'
            );
        END IF;
    END$$;
    """)

    op.execute("""
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'moneyflow') THEN
            CREATE TYPE moneyflow AS ENUM ('INFLOW', 'OUTFLOW');
        END IF;
    END$$;
    """)

    op.execute("""
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'paymentmethod') THEN
            CREATE TYPE paymentmethod AS ENUM (
                'CASH',
                'CARD',
                'INSTAPAY',
                'VODAFONE_CASH',
                'BANK_TRANSFER',
                'OTHER'
            );
        END IF;
    END$$;
    """)

    op.execute("""
    DO $$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'paymentstatus') THEN
            CREATE TYPE paymentstatus AS ENUM (
                'UNPAID',
                'PARTIAL',
                'PAID',
                'WAIVED',
                'REFUNDED'
            );
        END IF;
    END$$;
    """)

    op.create_table(
        'clinic_ledger_entries',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('clinic_id', sa.UUID(), nullable=False),
        sa.Column('appointment_id', sa.UUID(), nullable=True),
        sa.Column('created_by', sa.UUID(), nullable=True),
        sa.Column('entry_type', postgresql.ENUM(name='ledgerentrytype', create_type=False), nullable=False),
        sa.Column('money_flow', postgresql.ENUM(name='moneyflow', create_type=False), nullable=False),
        sa.Column('payment_method', postgresql.ENUM(name='paymentmethod', create_type=False), nullable=True),
        sa.Column('amount', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('reference', sa.String(), nullable=True),
        sa.Column('effective_date', sa.Date(), server_default=sa.text('CURRENT_DATE'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['appointment_id'], ['appointments.id']),
        sa.ForeignKeyConstraint(['clinic_id'], ['clinics.id']),
        sa.ForeignKeyConstraint(['created_by'], ['users.id']),
        sa.PrimaryKeyConstraint('id')
    )

    op.add_column('appointments', sa.Column('fee_amount', sa.Numeric(precision=12, scale=2), nullable=True))
    op.add_column('appointments', sa.Column('discount_amount', sa.Numeric(precision=12, scale=2), nullable=True))
    op.add_column('appointments', sa.Column('total_due_amount', sa.Numeric(precision=12, scale=2), nullable=True))
    op.add_column('appointments', sa.Column('total_paid_amount', sa.Numeric(precision=12, scale=2), nullable=True))
    op.add_column('appointments', sa.Column('balance_amount', sa.Numeric(precision=12, scale=2), nullable=True))
    op.add_column(
        'appointments',
        sa.Column(
            'payment_status',
            postgresql.ENUM(name='paymentstatus', create_type=False),
            nullable=False,
            server_default='UNPAID',
        )
    )
    op.add_column('appointments', sa.Column('payment_note', sa.Text(), nullable=True))

    op.alter_column('appointments', 'payment_status', server_default=None)


def downgrade() -> None:
    op.drop_column('appointments', 'payment_note')
    op.drop_column('appointments', 'payment_status')
    op.drop_column('appointments', 'balance_amount')
    op.drop_column('appointments', 'total_paid_amount')
    op.drop_column('appointments', 'total_due_amount')
    op.drop_column('appointments', 'discount_amount')
    op.drop_column('appointments', 'fee_amount')

    op.drop_table('clinic_ledger_entries')

    op.execute("DROP TYPE IF EXISTS paymentstatus")
    op.execute("DROP TYPE IF EXISTS paymentmethod")
    op.execute("DROP TYPE IF EXISTS moneyflow")
    op.execute("DROP TYPE IF EXISTS ledgerentrytype")