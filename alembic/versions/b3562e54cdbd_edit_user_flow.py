"""edit user flow

Revision ID: b3562e54cdbd
Revises: 8a6384171388
Create Date: 2026-04-10 17:42:02.739734
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "b3562e54cdbd"
down_revision: Union[str, None] = "8a6384171388"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


userrole_enum = postgresql.ENUM(
    "clinic_manager",
    "doctor",
    "patient",
    name="userrole",
    create_type=False,
)


def upgrade() -> None:
    bind = op.get_bind()

    # Reuse existing enum safely. If it does not exist for some reason, create it once.
    userrole_enum.create(bind, checkfirst=True)

    # 1) Create membership table
    op.create_table(
        "clinic_memberships",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("clinic_id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("role", userrole_enum, nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=True),
        sa.Column(
            "joined_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["clinic_id"], ["clinics.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("clinic_id", "user_id", name="uq_clinic_user_membership"),
    )

    # 2) Backfill memberships from existing users before dropping users.clinic_id
    op.execute("""
        INSERT INTO clinic_memberships (id, clinic_id, user_id, role, is_active, joined_at)
        SELECT gen_random_uuid(), clinic_id, id, role, COALESCE(is_active, false), now()
        FROM users
    """)

    # 3) Add clinic_id to doctor_profiles as nullable first
    op.add_column("doctor_profiles", sa.Column("clinic_id", sa.UUID(), nullable=True))

    # Backfill doctor_profiles.clinic_id from users table before users.clinic_id is removed
    op.execute("""
        UPDATE doctor_profiles dp
        SET clinic_id = u.clinic_id
        FROM users u
        WHERE dp.user_id = u.id
    """)

    op.alter_column("doctor_profiles", "clinic_id", nullable=False)
    op.drop_constraint("doctor_profiles_user_id_key", "doctor_profiles", type_="unique")
    op.create_unique_constraint(
        "uq_doctor_profile_user_clinic",
        "doctor_profiles",
        ["user_id", "clinic_id"],
    )
    op.create_foreign_key(
        "fk_doctor_profiles_clinic_id_clinics",
        "doctor_profiles",
        "clinics",
        ["clinic_id"],
        ["id"],
    )

    # 4) Add clinic_id to patient_profiles as nullable first
    op.add_column("patient_profiles", sa.Column("clinic_id", sa.UUID(), nullable=True))

    # Backfill patient_profiles.clinic_id from users table before users.clinic_id is removed
    op.execute("""
        UPDATE patient_profiles pp
        SET clinic_id = u.clinic_id
        FROM users u
        WHERE pp.user_id = u.id
    """)

    op.alter_column("patient_profiles", "clinic_id", nullable=False)
    op.drop_constraint("patient_profiles_user_id_key", "patient_profiles", type_="unique")
    op.create_unique_constraint(
        "uq_patient_profile_user_clinic",
        "patient_profiles",
        ["user_id", "clinic_id"],
    )
    op.create_foreign_key(
        "fk_patient_profiles_clinic_id_clinics",
        "patient_profiles",
        "clinics",
        ["clinic_id"],
        ["id"],
    )

    # 5) Replace per-clinic uniqueness with global uniqueness
    op.drop_constraint("uq_user_email_per_clinic", "users", type_="unique")
    op.drop_constraint("uq_user_phone_per_clinic", "users", type_="unique")

    op.drop_index("ix_users_email", table_name="users")
    op.create_index(op.f("ix_users_email"), "users", ["email"], unique=True)

    op.drop_index("ix_users_phone_number", table_name="users")
    op.create_index(op.f("ix_users_phone_number"), "users", ["phone_number"], unique=True)

    # 6) Drop clinic_id from users only after all backfills are done
    op.drop_constraint("users_clinic_id_fkey", "users", type_="foreignkey")
    op.drop_column("users", "clinic_id")


def downgrade() -> None:
    # 1) Add clinic_id back to users as nullable first
    op.add_column("users", sa.Column("clinic_id", sa.UUID(), nullable=True))

    # Restore clinic_id from memberships
    op.execute("""
        UPDATE users u
        SET clinic_id = cm.clinic_id
        FROM clinic_memberships cm
        WHERE cm.user_id = u.id
    """)

    op.alter_column("users", "clinic_id", nullable=False)
    op.create_foreign_key("users_clinic_id_fkey", "users", "clinics", ["clinic_id"], ["id"])

    # 2) Restore non-unique indexes
    op.drop_index(op.f("ix_users_phone_number"), table_name="users")
    op.create_index("ix_users_phone_number", "users", ["phone_number"], unique=False)

    op.drop_index(op.f("ix_users_email"), table_name="users")
    op.create_index("ix_users_email", "users", ["email"], unique=False)

    # 3) Restore old per-clinic unique constraints
    op.create_unique_constraint("uq_user_phone_per_clinic", "users", ["clinic_id", "phone_number"])
    op.create_unique_constraint("uq_user_email_per_clinic", "users", ["clinic_id", "email"])

    # 4) Remove patient_profiles clinic link
    op.drop_constraint("fk_patient_profiles_clinic_id_clinics", "patient_profiles", type_="foreignkey")
    op.drop_constraint("uq_patient_profile_user_clinic", "patient_profiles", type_="unique")
    op.create_unique_constraint("patient_profiles_user_id_key", "patient_profiles", ["user_id"])
    op.drop_column("patient_profiles", "clinic_id")

    # 5) Remove doctor_profiles clinic link
    op.drop_constraint("fk_doctor_profiles_clinic_id_clinics", "doctor_profiles", type_="foreignkey")
    op.drop_constraint("uq_doctor_profile_user_clinic", "doctor_profiles", type_="unique")
    op.create_unique_constraint("doctor_profiles_user_id_key", "doctor_profiles", ["user_id"])
    op.drop_column("doctor_profiles", "clinic_id")

    # 6) Drop memberships table
    op.drop_table("clinic_memberships")