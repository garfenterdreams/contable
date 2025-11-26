# GARFENTER PLAN: Garfenter Contable (bigcapital)

> **⭐ PREFERRED PRODUCT** - Selected as best Accounting platform for Garfenter Suite (Score: 9/10)

**Product Name:** Garfenter Contable
**Based On:** Bigcapital
**Category:** Financial Management
**Original Language:** English

---

## Executive Summary

Bigcapital is a modern accounting software with intelligent reporting - QuickBooks/Xero alternative.

---

## 1. LOCALIZATION & CONTAINERIZATION

**Create:** `docker-compose.garfenter.yml`
```yaml
version: '3.8'

services:
  garfenter-capital:
    build: .
    image: garfenter/capital:latest
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://garfenter:${DB_PASSWORD}@garfenter-postgres/capital
      - DEFAULT_LOCALE=es
      - DEFAULT_CURRENCY=GTQ
    depends_on:
      - garfenter-postgres
      - garfenter-redis
    networks:
      - garfenter-network

  garfenter-postgres:
    image: postgres:15-alpine
    networks:
      - garfenter-network

  garfenter-redis:
    image: redis:7-alpine
    networks:
      - garfenter-network

networks:
  garfenter-network:
```

---

## 2. IMPLEMENTATION TIMELINE

**Total:** 2 weeks

---

*Plan Version: 1.0 | Garfenter Product Suite*
