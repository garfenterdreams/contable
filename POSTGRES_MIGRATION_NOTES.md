# PostgreSQL Migration Notes

## Important: Database Compatibility

This Garfenter Contable deployment has been configured to use **PostgreSQL 15** instead of the original **MariaDB/MySQL** database.

### Potential Compatibility Issues

Bigcapital was originally designed for MySQL/MariaDB. While PostgreSQL is specified in your requirements, you may encounter compatibility issues with:

1. **SQL Syntax Differences**
   - MySQL uses backticks (\`) for identifiers, PostgreSQL uses double quotes (")
   - `LIMIT` syntax differs
   - Date/time functions differ
   - String concatenation differs (|| vs CONCAT)

2. **Knex.js Compatibility**
   - The server uses Knex.js ORM which supports both databases
   - Most queries should work, but some raw SQL may need adjustment

3. **Migration Scripts**
   - Existing migrations are written for MySQL
   - May need to be adapted for PostgreSQL

### Recommendations

#### Option 1: Use Original MariaDB (Recommended for Production)

If you encounter issues, you can switch back to MariaDB by modifying `docker-compose.garfenter.yml`:

```yaml
# Replace garfenter-postgres service with:
garfenter-mariadb:
  image: mariadb:10.11
  container_name: garfenter-contable-mariadb
  restart: unless-stopped
  environment:
    - MYSQL_DATABASE=${SYSTEM_DB_NAME:-garfenter_system}
    - MYSQL_USER=${DB_USER:-garfenter}
    - MYSQL_PASSWORD=${DB_PASSWORD:-garfenter_secure_2024}
    - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-root}
    - TZ=America/Guatemala
  volumes:
    - garfenter_mysql_data:/var/lib/mysql
  ports:
    - "${MYSQL_PORT:-3306}:3306"
  networks:
    - garfenter_network
```

And update environment variables:

```bash
DB_HOST=garfenter-mariadb
DB_PORT=3306
# Remove DB_CHARSET or set to utf8mb4
```

#### Option 2: Test PostgreSQL Compatibility

1. **Start the system**:
   ```bash
   ./garfenter-start.sh start
   ```

2. **Monitor logs for database errors**:
   ```bash
   ./garfenter-start.sh logs garfenter-contable
   ```

3. **Check migration logs**:
   ```bash
   docker logs garfenter-contable-migration
   ```

4. **Test basic operations**:
   - Create a user account
   - Create a company
   - Create an invoice
   - Run a report

### Database Adapter Configuration

If you need to explicitly configure the database adapter, modify the server's Knex configuration:

**For PostgreSQL:**
```javascript
{
  client: 'pg',
  connection: {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.SYSTEM_DB_NAME,
    charset: 'utf8'
  }
}
```

**For MySQL/MariaDB:**
```javascript
{
  client: 'mysql2',
  connection: {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.SYSTEM_DB_NAME,
    charset: 'utf8mb4'
  }
}
```

### Testing Checklist

Before deploying to production, test these core features:

- [ ] User registration and authentication
- [ ] Company creation and settings
- [ ] Chart of accounts
- [ ] Customer management
- [ ] Vendor management
- [ ] Invoice creation and editing
- [ ] Payment recording
- [ ] Expense tracking
- [ ] Financial reports (Balance Sheet, P&L)
- [ ] PDF generation (invoices, reports)
- [ ] Multi-currency operations
- [ ] Bank reconciliation
- [ ] Tax calculations (IVA for Guatemala)

### Known Bigcapital Database Dependencies

Based on the package.json, the project uses:

- `mysql`: ^2.18.1
- `mysql2`: ^3.11.3
- `knex`: ^3.1.0 (supports both MySQL and PostgreSQL)

The presence of MySQL drivers suggests strong MySQL/MariaDB orientation. To use PostgreSQL, you may need to:

1. Install PostgreSQL driver in the server package:
   ```bash
   cd packages/server
   pnpm add pg
   ```

2. Update Knex configuration to use 'pg' client instead of 'mysql2'

### Getting Help

If you encounter database-related errors:

1. Check server logs: `docker logs garfenter-contable-api`
2. Check migration logs: `docker logs garfenter-contable-migration`
3. Check PostgreSQL logs: `docker logs garfenter-contable-postgres`
4. Review Bigcapital issues: https://github.com/bigcapitalhq/bigcapital/issues

### Production Recommendation

**For production deployment, we recommend using MariaDB 10.11 (the original database) to ensure full compatibility.** PostgreSQL support would require thorough testing and potentially code modifications to the Bigcapital source.

If PostgreSQL is a hard requirement, consider:
1. Running comprehensive tests on a staging environment
2. Contributing PostgreSQL compatibility patches to the Bigcapital project
3. Maintaining a fork with PostgreSQL-specific modifications

### Alternative: Hybrid Approach

You can also use PostgreSQL for new custom tables while keeping MariaDB for core Bigcapital tables:

```yaml
services:
  garfenter-postgres:
    # PostgreSQL for custom tables

  garfenter-mariadb:
    # MariaDB for core Bigcapital tables
```

This approach provides flexibility but adds complexity to the deployment.
