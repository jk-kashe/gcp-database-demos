from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    api_base_url: str

settings = Settings()