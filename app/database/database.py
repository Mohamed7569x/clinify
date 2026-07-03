from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker


URL_DATABASE = 'postgresql://postgres:mohamedx@localhost:5432/clinify'

engine = create_engine(URL_DATABASE)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
