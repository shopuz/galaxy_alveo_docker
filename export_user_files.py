import sys
import os
import shutil
import subprocess

PG_DATA_DIR_DEFAULT = sys.argv[1] or "/var/lib/postgresql/9.1/main"
PG_DATA_DIR_HOST = "/export/postgresql/9.1/main/"
PG_CONF = '/etc/postgresql/9.1/main/postgresql.conf'

def change_path( src ):
    """
        src will be copied to /export/`src` and a symlink will be placed in src pointing to /export/
    """
    if os.path.exists( src ):
        dest = os.path.join( '/export/', src.strip('/') )
        # if destination is empty move all files into /export/ and symlink back to source
        if not os.path.exists( dest ):
            dest_dir = os.path.dirname(dest)
            if not os.path.exists( dest_dir ):
                os.makedirs(dest_dir)
            shutil.move( src, dest )
            os.symlink( dest, src.rstrip('/') )
        # if destination exists (e.g. continuing a previous session), remove source and symlink
        else:
            if os.path.isdir( src ):
                shutil.rmtree( src )
            else:
                os.unlink( src )
            os.symlink( dest, src.rstrip('/') )


if __name__ == "__main__":

    if os.path.exists('/export/'):
        change_path('/mnt/galaxy/galaxy-app/universe_wsgi.ini')
        change_path('/mnt/galaxy/galaxy-app/database/files/')
        change_path('/mnt/galaxy/galaxy-app/database/job_working_directory/')
        change_path('/mnt/galaxy/galaxy-app/tool_deps/')
        change_path('/shed_tools/')
        change_path('/mnt/galaxy/galaxy-app/job_conf.xml')
        change_path('/mnt/galaxy/galaxy-app/shed_tool_conf.xml')

        if not os.path.exists( PG_DATA_DIR_HOST ) or 'PG_VERSION' not in os.listdir( PG_DATA_DIR_HOST ):
            dest_dir = os.path.dirname( PG_DATA_DIR_HOST )
            if not os.path.exists( dest_dir ):
                os.makedirs(dest_dir)
            # User given dbpath, usually a directory from the host machine
            # copy the postgresql data folder to the new location
            subprocess.call('cp -R %s/* %s' % (PG_DATA_DIR_DEFAULT, PG_DATA_DIR_HOST), shell=True)
            # copytree needs an non-existing dst dir, how annoying :(
            #shutil.copytree(PG_DATA_DIR_DEFAULT, PG_DATA_DIR_HOST)
            subprocess.call('chown -R postgres:postgres /export/postgresql/', shell=True)
            subprocess.call('chmod -R 0755 /export/', shell=True)
            subprocess.call('chmod -R 0700 %s' % PG_DATA_DIR_HOST, shell=True)
        # change data_directory of PostgreSQL to the new location
        new_data_directory = "'%s'" % PG_DATA_DIR_HOST
        cmd = 'sed -i "s|data_directory = .*|data_directory = %s|g" %s' % (new_data_directory, PG_CONF)
        subprocess.call(cmd, shell=True)



