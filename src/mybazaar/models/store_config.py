from sqlalchemy import String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class StoreConfig(Base):
    __tablename__ = "store_config"

    key: Mapped[str] = mapped_column(String(100), primary_key=True)
    value = mapped_column(JSONB, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
