# playdoh-specific commands that get playdoh all going so you don't
# have to.

# TODO: Make this rely on things that are not straight-up exec.
class playdoh {
    file { "$PROJ_DIR/careers/settings/local.py":
        ensure => file,
        source => "$PROJ_DIR/careers/settings/local.py-dist",
        replace => false;
    }

    exec { "create_mysql_database":
        command => "mysqladmin -uroot create $DB_NAME",
        unless  => "mysql -uroot -B --skip-column-names -e 'show databases' | /bin/grep '$DB_NAME'",
        require => File["$PROJ_DIR/careers/settings/local.py"]
    }

    exec { "grant_mysql_database":
        command => "mysql -uroot -B -e'GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost # IDENTIFIED BY \"$DB_PASS\"'",
        unless  => "mysql -uroot -B --skip-column-names mysql -e 'select user from user' | grep '$DB_USER'",
        require => Exec["create_mysql_database"];
    }

    exec { "syncdb":
        cwd => "$PROJ_DIR",
        command => "python ./manage.py syncdb --noinput",
        require => Exec["grant_mysql_database"];
    }

    exec { "sql_migrate":
        cwd => "$PROJ_DIR",
        command => "python ./manage.py migrate",
        require => [
            Service["mysql"],
            Package["python2.7-dev", "libapache2-mod-wsgi", "python-wsgi-intercept" ],
            Exec["syncdb"]
        ];
    }
}
