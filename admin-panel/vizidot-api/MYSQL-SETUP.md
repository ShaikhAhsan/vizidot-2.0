# MySQL Connection Fix

If you get: **"Access denied for user 'api_vizidot_user'@'%' to database 'u5gdchot-vizidot'"**

Run these commands in your MySQL (Coolify MySQL console, phpMyAdmin, or `mysql` CLI):

```sql
-- Option A: If user exists but lacks privileges
GRANT ALL PRIVILEGES ON `u5gdchot-vizidot`.* TO 'api_vizidot_user'@'%';
FLUSH PRIVILEGES;

-- Option B: If user doesn't exist yet (create + grant)
CREATE USER IF NOT EXISTS 'api_vizidot_user'@'%' IDENTIFIED BY 'your_password_here';
GRANT ALL PRIVILEGES ON `u5gdchot-vizidot`.* TO 'api_vizidot_user'@'%';
FLUSH PRIVILEGES;
```

Replace `your_password_here` with your actual `DB_PASSWORD` from `.env`.

**Note:** Use `'%'` to allow connections from any host. If you created the user for a specific IP (e.g. `82.197.48.195`), ensure the API connects from that IP, or create the user with `'%'` as above.
