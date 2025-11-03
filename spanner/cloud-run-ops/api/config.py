from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    spanner_instance_id: str
    spanner_database_id: str
    spanner_api_endpoint: Optional[str] = None

settings = Settings()