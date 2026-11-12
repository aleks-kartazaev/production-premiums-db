C4Container
  title Container — Учёт выработки и премий

  Person(master, "Мастер")
  Person(manager, "Начальник участка")

  System_Boundary(system, "Система учёта") {
    Container(web, "Веб-приложение", "React", "Интерфейс для мастера и начальника")
    Container(api, "REST API", "Python/FastAPI", "Бизнес-логика")
    ContainerDb(db, "База данных", "PostgreSQL", "Хранит выработку, премии, нормы")
  }

  Rel(master, web, "Работает в браузере", "HTTPS")
  Rel(manager, web, "Утверждает", "HTTPS")
  Rel(web, api, "Запросы", "JSON/HTTP")
  Rel(api, db, "Читает/пишет", "SQL")