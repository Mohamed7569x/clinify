from fastapi import FastAPI
from app.routers import auth, audit_logs,branches,join, announcements,broadcast,finance, public_branches, clinic_group, appointments, chat, clinic, patients, prescriptions, medical_files,doctors,notifications,reviews,schedules,specialties,subscription
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from starlette.requests import Request


app = FastAPI()
app.include_router(join.router)
app.include_router(auth.router)
app.include_router(finance.router)
app.include_router(public_branches.router)
app.include_router(branches.router)
app.include_router(clinic_group.router)
app.include_router(broadcast.router)
app.include_router(auth.fcmrouter)
app.include_router(audit_logs.router)
app.include_router(announcements.router)
app.include_router(appointments.router)
app.include_router(chat.router)
app.include_router(clinic.router)
app.include_router(patients.router)
app.include_router(prescriptions.router)
app.include_router(medical_files.router)
app.include_router(doctors.router)
app.include_router(notifications.router)
app.include_router(reviews.router)
app.include_router(schedules.router)
app.include_router(schedules.blocked_router)
app.include_router(specialties.router)
app.include_router(subscription.router)


# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.mount("/.well-known", StaticFiles(directory="static/.well-known"), name="well-known")
# Templates
templates = Jinja2Templates(directory="static")


@app.get("/")
async def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.get("/dashboard")
async def home(request: Request):
    return templates.TemplateResponse("dashboard.html", {"request": request})

@app.get("/register")
async def login(request: Request):
    return templates.TemplateResponse("register.html", {"request": request})

@app.get("/login")
async def login(request: Request):
    return templates.TemplateResponse("login.html", {"request": request})


origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

    