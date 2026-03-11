"""IST Timezone and government schemes

Revision ID: 7b794543cce9
Revises: 271f51a30597
Create Date: 2026-03-12 00:28:02.434464

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7b794543cce9'
down_revision: Union[str, Sequence[str], None] = '271f51a30597'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Upgrade Scheme tables to be timezone-aware
    op.alter_column('raw_schemes', 'created_at', type_=sa.DateTime(timezone=True))
    op.alter_column('cleaned_schemes', 'created_at', type_=sa.DateTime(timezone=True))

    # 2. Drop the old UTC server_defaults from the database 
    # so your new Python IST function takes full control
    op.alter_column('users', 'created_at', server_default=None)
    op.alter_column('chat_sessions', 'created_at', server_default=None)
    op.alter_column('chat_messages', 'created_at', server_default=None)
    op.alter_column('weather_cache', 'fetched_at', server_default=None)


def downgrade() -> None:
    # Revert to standard DateTime without timezone if we ever rollback
    op.alter_column('raw_schemes', 'created_at', type_=sa.DateTime())
    op.alter_column('cleaned_schemes', 'created_at', type_=sa.DateTime())
