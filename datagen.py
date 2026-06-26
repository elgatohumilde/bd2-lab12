import csv
import random
from datetime import date

from faker import Faker

fake = Faker("es_ES")

NUM_ROWS = 50_000

PATIENTS_FILE = "pacientes.csv"
ATTENTION_FILE = "atencionmedica.csv"

cities = [
    "Lima",
    "Arequipa",
    "Cusco",
    "Trujillo",
    "Piura",
    "Chiclayo",
    "Iquitos",
    "Tacna",
    "Huancayo",
    "Puno",
]

diagnosticos = [
    "Diabetes",
    "Hipertensión",
    "Obesidad",
    "Cardiopatía",
    "Asma",
    "Gripe",
    "Covid",
    "Anemia",
    "Migraña",
    "Gastritis",
]

used_dnis = set()
all_dnis = []


def generate_unique_dni():
    while True:
        dni = f"{random.randint(0, 99999999):08d}"
        if dni not in used_dnis:
            used_dnis.add(dni)
            all_dnis.append(dni)
            return dni


# -------------------------
# Generate pacientes.csv
# -------------------------
with open(PATIENTS_FILE, "w", newline="", encoding="utf-8") as csvfile:
    writer = csv.writer(csvfile)

    writer.writerow(
        [
            "dni",
            "nombre",
            "apellidos",
            "fechanacimiento",
            "sexo",
            "ciudadorigen",
        ]
    )

    for _ in range(NUM_ROWS):
        sexo = random.choice(["M", "F"])

        if sexo == "M":
            first_name = fake.first_name_male()
        else:
            first_name = fake.first_name_female()

        last_name = fake.last_name() + " " + fake.last_name()
        birth_date = fake.date_of_birth(minimum_age=0, maximum_age=100)

        writer.writerow(
            [
                generate_unique_dni(),
                first_name,
                last_name,
                birth_date.isoformat(),
                sexo,
                random.choice(cities),
            ]
        )

print(f"Generated {NUM_ROWS:,} rows in '{PATIENTS_FILE}'")


# -------------------------
# Generate atencionmedica.csv
# -------------------------
with open(ATTENTION_FILE, "w", newline="", encoding="utf-8") as csvfile:
    writer = csv.writer(csvfile)

    writer.writerow(
        [
            "DNI",
            "CodMedico",
            "Ciudad",
            "Diagnostico",
            "Peso",
            "Talla",
            "PresionArterial",
            "Edad",
            "FechaAtencion",
        ]
    )

    for _ in range(NUM_ROWS):
        sistolica = random.randint(90, 180)
        diastolica = random.randint(60, 110)

        writer.writerow(
            [
                random.choice(all_dnis),  # Existing patient
                random.randint(1, 500),  # CodMedico
                random.choice(cities),
                random.choice(diagnosticos),
                round(random.uniform(40, 120), 2),  # Peso
                round(random.uniform(1.40, 2.10), 2),  # Talla
                f"{sistolica}/{diastolica}",
                random.randint(0, 100),
                fake.date_between(start_date="-5y", end_date="today").isoformat(),
            ]
        )

print(f"Generated {NUM_ROWS:,} rows in '{ATTENTION_FILE}'")
