

The URL of the web site is:

http://socialarchive.iath.virginia.edu/dev

Files in the production web directory are managed from the source repository via svn.

From source directory, commit changes and update web site:

    svn commit -m"logo swap"; cd /projects/socialarchive/development; svn update; chmod g+w *; cd -

Commit changes from the source directory:

    cd /home/twl8n/eac_project/web_marc2cpf
    svn commit -m"commit message here"


Initial checkout into the web site:

    cd /projects/socialarchive/development
    svn co http://socialarchive.iath.virginia.edu/repos/twl8n/web_marc2cpf .
    chmod g+rw *

Subsequent updates of the web site:

    cd /projects/socialarchive/development
    svn update
    chmod g+rw *


Script-writable data is in a data_dir (see .app_config, and /home/twl8n/.app_config) owned by apache:apache
since httpd runs as apache:apache, and we're not yet set up to do suexec. The data_dir is not web
accessible. Something like this needs to be done:

    cd ~/
    mkdir data
    sudo chown apache:apache data


Change dir back to the document root of the web site.

Copy app_config.dist to ~/.app_config and edit with appropriate values

Copy app_config_redirect.dist to .app_config and edit the redirect path to be the full path to the
"real" .app_config. Even though our .htaccess prevents serving dot files, we keep the real config file in a
non-web accessible directory.

Copy htaccess.dist to .htaccess and review/edit as necessary.

Create symbolic links to files which originate in the EAC CPF utils repository. Here is a list of files that
are handled as symlinks to the eac_project source directory:

    > ls -l | grep lrw
    lrwxrwxrwx 1 twl8n devteam        30 Aug 12 16:34 av.xsl -> /home/twl8n/eac_project/av.xsl
    lrwxrwxrwx 1 twl8n devteam        35 Feb  4  2013 eac_cpf.xsl -> /home/twl8n/eac_project/eac_cpf.xsl
    lrwxrwxrwx 1 twl8n devteam        43 Aug 12 16:38 geonames_places.xml -> /home/twl8n/eac_project/geonames_places.xml
    lrwxrwxrwx 1 twl8n devteam        31 Feb  4  2013 lib.xsl -> /home/twl8n/eac_project/lib.xsl
    lrwxrwxrwx 1 twl8n devteam        39 Feb  4  2013 occupations.xml -> /home/twl8n/eac_project/occupations.xml
    lrwxrwxrwx 1 twl8n devteam        41 Feb  4  2013 oclc_marc2cpf.xsl -> /home/twl8n/eac_project/oclc_marc2cpf.xsl
    lrwxrwxrwx 1 twl8n devteam        38 Feb  4  2013 session_lib.pm -> /home/twl8n/eac_project/session_lib.pm
    lrwxrwxrwx 1 twl8n devteam        47 Feb  4  2013 vocabularylanguages.rdf -> /home/twl8n/eac_project/vocabularylanguages.rdf
    lrwxrwxrwx 1 twl8n devteam        46 Feb  4  2013 vocabularyrelators.rdf -> /home/twl8n/eac_project/vocabularyrelators.rdf
    lrwxrwxrwx 1 twl8n devteam        41 Feb  4  2013 worldcat_code.xml -> /home/twl8n/eac_project/worldcat_code.xml
