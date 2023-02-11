# Resetting `root` password

## Pre-requisites

- Running `mariadb` server
- OS is a linux distro, like Ubuntu or Arch

## Steps

### Stop DB Server

```bash
# To verify that the mariadb instance is running
sudo systemctl status mariadb
sudo systemctl stop mariadb
```

### Bypass user privileges when accessing the database

`--skip-grant-tables` prevents load the grant tables which contain user privilege information, which will enable us to bypass user privileges.

`--skip-networking` prevents other clients from connecting to the database after it is restarted while the root password is being reset.

```bash
sudo mysqld_safe --skip-grant-tables --skip-networking &
```

Then "Enter" to ensure the mysql daemon runs in the background.

You should then be able to access the datbase without a password.

```bash
mariadb -u root
```

### Change root password

Reload the grant tables in the db server.

```sql
FLUSH PRIVILEGES;
```

Replace `'new_password'` with your password.

```sql
-- mysql >=5.7.6 | mariadb >=10.1.20
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
-- mysql <5.7.6 | mariadb <10.1.20
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('new_password');
-- An untested alternative
UPDATE mysql.user SET authentication_string = PASSWORD('new_password') WHERE User = 'root' AND Host = 'localhost';
```

Once done, exit the mariadb / mysql prompt.

### Restart db server normally

Kill the db server.

```bash
# mariadb
sudo kill `/var/run/mariadb/mariadb.pid`
# mysql
sudo kill `cat /var/run/mysqld/mysqld.pid`
```

Start the db server normally via `systemctl`.

```bash
systemctl status mariadb
# Verify it is off
systemctl start mariadb
```

Log into the root account with the newly set root password.

```bash
mariadb -u root -p
```

## References

- https://www.digitalocean.com/community/tutorials/how-to-reset-your-mysql-or-mariadb-root-password#step-1-identifying-the-database-version