import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ..models.user import User
from ..schemas.user import UserCreate
from ..utils.security import hash_password, verify_password
from ..utils.exceptions import UserAlreadyExistsError, InvalidCredentialsError, UserNotFoundError


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_user(self, data: UserCreate) -> User:
        result = await self.db.execute(select(User).where(User.username == data.username))
        if result.scalar_one_or_none():
            raise UserAlreadyExistsError(f"Username '{data.username}' is already taken")

        user = User(
            id=str(uuid.uuid4()),
            username=data.username,
            password_hash=hash_password(data.password),
        )
        self.db.add(user)
        await self.db.flush()
        return user

    async def authenticate_user(self, username: str, password: str) -> User:
        result = await self.db.execute(select(User).where(User.username == username))
        user = result.scalar_one_or_none()
        if not user or not verify_password(password, user.password_hash):
            raise InvalidCredentialsError("Invalid username or password")
        return user

    async def get_user_by_id(self, user_id: str) -> User:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise UserNotFoundError(f"User '{user_id}' not found")
        return user

    async def update_funds(self, user_id: str, amount: float) -> User:
        user = await self.get_user_by_id(user_id)
        user.account_funds = float(user.account_funds) + amount
        await self.db.flush()
        return user

    async def update_shields(self, user_id: str, delta: int) -> User:
        user = await self.get_user_by_id(user_id)
        user.shields_owned = user.shields_owned + delta
        await self.db.flush()
        return user
