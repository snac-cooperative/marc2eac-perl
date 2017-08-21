#!/usr/bin/perl

use strict;
use CGI;
# use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
use File::Temp qw(tempfile tempdir);
use HTML::Template;
use session_lib qw(process_template untaint save_upload_file app_config user_config check_config read_file get_url);
use File::Basename;

# Many symlinks are necessary for this to work. Unfortunately, the code does not sanity check itself, and
# changes made to the main eac_project XSL code can break this web site.

# > ls -l | grep lrw
# lrwxrwxrwx 1 twl8n devteam        30 Aug 12 16:34 av.xsl -> /home/twl8n/eac_project/av.xsl
# lrwxrwxrwx 1 twl8n devteam        35 Feb  4  2013 eac_cpf.xsl -> /home/twl8n/eac_project/eac_cpf.xsl
# lrwxrwxrwx 1 twl8n devteam        43 Aug 12 16:38 geonames_places.xml -> /home/twl8n/eac_project/geonames_places.xml
# lrwxrwxrwx 1 twl8n devteam        31 Feb  4  2013 lib.xsl -> /home/twl8n/eac_project/lib.xsl
# lrwxrwxrwx 1 twl8n devteam        39 Feb  4  2013 occupations.xml -> /home/twl8n/eac_project/occupations.xml
# lrwxrwxrwx 1 twl8n devteam        41 Feb  4  2013 oclc_marc2cpf.xsl -> /home/twl8n/eac_project/oclc_marc2cpf.xsl
# lrwxrwxrwx 1 twl8n devteam        38 Feb  4  2013 session_lib.pm -> /home/twl8n/eac_project/session_lib.pm
# lrwxrwxrwx 1 twl8n devteam        47 Feb  4  2013 vocabularylanguages.rdf -> /home/twl8n/eac_project/vocabularylanguages.rdf
# lrwxrwxrwx 1 twl8n devteam        46 Feb  4  2013 vocabularyrelators.rdf -> /home/twl8n/eac_project/vocabularyrelators.rdf
# lrwxrwxrwx 1 twl8n devteam        41 Feb  4  2013 worldcat_code.xml -> /home/twl8n/eac_project/worldcat_code.xml


# No String:Util in the RHEL packages, and we aren't quite ready to use perlbrew for httpd.
# use String::Util 'trim';

# Yes, they're globals, but used readonly.
my $data_dir = '';
my $data_root = '';
my %cf; # The config is global. 

# Start by dup'ing stdout so we can restore it later, and so we simply directly use in in any print statements
# that need to print to STDOUT.
open(my $orig_stdout, ">&STDOUT"); 

main();
exit();

sub main
{
    my $qq = new CGI; 
    my %ch = $qq->Vars();

    %cf = app_config();

    # Missing config will cause the script to exit with an error, and the end user will see the Apache
    # internal error page. check_config() should be rewritten to create a better error page.

    check_config(\%cf, "data_dir,find_exe,data_root,chmod_exe,document_root,yaz_marcdump_exe");

    $data_dir = $cf{data_dir};
    $data_root = $cf{data_root};

    # There is no need to quote $data_root with \Q \E or escape characters since the string value is not
    # limited by inline regex syntax. There can be a / in the string ($stuff, $data_root) with out escaping as
    # \/. Try these at the command line.
    
    # perl -e '$stuff = "stuff/"; $var = "pie and stuff/"; $var =~ m/($stuff)/; print $1;'
    # perl -e '$stuff = "stuff.+"; $var = "pie and stuff/"; $var =~ m/($stuff)/; print $1;'
    # perl -e '$stuff = "stuff.+"; $var = "pie and stuff//"; $var =~ m/($stuff)/; print $1;'
    # perl -e '$stuff = "stuff.*"; $var = "pie and stuff//"; $var =~ m/($stuff)/; print $1;'
    # perl -e '$stuff = "stuff.*"; $var = "pie and stuff"; $var =~ m/($stuff)/; print $1;'
    # perl -e '$stuff = "stuff"; $var = "pie and stuff/"; $var =~ m/($stuff)/; print $1;'
    # perl -e '$stuff = qw/stuff./; $var = "pie and stuff/"; $var =~ m/($stuff)/; print $1;'

    if ($data_dir !~ m/^$data_root/)
    {
        print STDERR "Error: config data_root: $data_root is not prefix of data_dir: $data_dir\n";
        exit();
    }

    sanity_check_environment();

    clean_old_files();

    my $msg = '';
    my $allhtml = process_template("index_template.html");
    my $template = HTML::Template->new(scalarref => \$allhtml,
                                       die_on_bad_params => 0);

    # Set all the divs to not visible, and later on only make the one we care about visible.

    $template->param(show_paste => 'none');
    $template->param(show_temp => 'none');
    $template->param(show_dir => 'none');
    $template->param(ask_dir => 'none');
    $template->param(show_upload => 'none');

    if ($ch{state} eq 'show_paste')
    {
        $template->param(show_paste => 'block');
    }
    elsif ($ch{state} eq 'get_data')
    {
        my $real_data_path = user_to_real(untaint($ch{data_path}));
        
        # basename, directories, suffix
        # perl -e 'use File::Basename; ($ba, $dr, $sf)=fileparse("/home/twl8n/stuff.txt", ("txt")); print "b:$ba d:$dr s:$sf";'
        # b:stuff. d:/home/twl8n/ s:txt

        (my $basename, my $directories, my $suffix) = fileparse($real_data_path, ('xml', 'zip', 'mrc'));
        
        if (-e $real_data_path && ($suffix eq 'xml' || $suffix eq 'zip' || $suffix eq 'mrc') )
        {
            # # Dup stdout back to the original
            # open(STDOUT, ">&", $orig_stdout);
            if ($ch{type} eq 'download')
            {
                print $orig_stdout "Content-Type:application/x-download\n";
                print $orig_stdout "Content-Disposition:attachment;filename=$basename$suffix\n\n";
            }
            elsif ($suffix eq 'xml')
            {
                print $orig_stdout "Content-Type:application/xml\n\n";
            }
            else
            {
                # Redundant, fail-safe. Force download for things we didn't anticipate.
                print $orig_stdout "Content-Type:application/x-download\n";
                print $orig_stdout "Content-Disposition:attachment;filename=$basename$suffix\n\n";
            }

            # In case you were wondering, .mrc files contain control chars, so even if you tell the browser
            # text/plain, the browser is not fooled and will only download, not display. Code in
            # build_file_list() marks .zip and .mrc as non-viewable so we don't end up in the confusing land
            # of "the browser is downloading a file I asked to view".

            print $orig_stdout read_file($real_data_path);
            exit();
            # $msg .= "File downloaded.<br>\n";
        }
        else
        {
            $msg .= "Download not supported.<br>\n";
        }

    }
    elsif ($ch{state} eq 'show_upload')
    {
        $template->param(show_upload => 'block');
    }
    elsif ($ch{state} eq 'ask_dir')
    {
        $template->param(ask_dir => 'block');
    }
    elsif ($ch{state} eq 'do_dir')
    {
        # Get a list of files in the user's data directory. The user has a unique directory inside the data
        # directory. data/arglebargle.
        
        (my $rec_ref) = build_file_list($ch{data_path});
        if ($rec_ref)
        {
            $template->param(recs => $rec_ref);
        }
        else
        {
            $msg .= "Bad data path: $ch{data_path}\n";
        }
        $template->param(show_dir => 'block');
    }
    elsif ($ch{state} eq 'do_process')
    {
        # Write the data from $ch{input} to the $input_file. $input_file is named "input" because it will be
        # the input for xlst processing later.

        my $input_ext = "mrc";

        # Match all input as a single line, that is: \n matches \s. Require <?xml as the first non-whitespace
        # in the input.

        if ($ch{input} =~ m/^\s*<\?xml/s)
        {
            $input_ext = "xml";
            $msg .= "Data appears to be .xml.\n";
        }
        elsif ($ch{input} =~ m/\036/s)
        {
            $msg .= "Data appears to be .mrc. Attempting to convert to XML and run.\n";
        }
        else
        {
            $msg .= "Data (apparently) not .mrc or .xml.";
            exit_to_home($template, $msg);
        }

        # What the heck is this exciting bit of Perl? You really should have commented this line that inits
        # tempdir.
        my $tempdir = tempdir ( DIR => $data_dir );
        my $input_file = "$tempdir/input.$input_ext";

        if (! open(my $fh, '>', $input_file))
        {
            write_log("Can't open file for write. input_file: $input_file tempdir: $tempdir\n");
            exit();
        }
        else
        {
            print $fh trim($ch{input});
            close($fh);
            write_log("Wrote to: $input_file\n");
        }
        
        my $last_dir = process_xslt($input_file, $tempdir);

        my $rec_ref = build_file_list("data/$last_dir");
        if ($rec_ref)
        {
            $template->param(recs => $rec_ref);
        }
        else
        {
            $msg .= "Bad data path: $ch{data_path}\n";
        }
        $template->param(show_dir => 'block');

        my $user_dir = real_to_user($tempdir);
        my $user_url = get_url() . "?state=do_dir&data_path=$user_dir";

        $template->param(show_temp => 'block');
        $template->param(tempdir => $user_dir);
        $template->param(user_url => $user_url);
    }
    elsif ($ch{state} eq 'do_upload')
    {
        # If $data_dir is /home/twl8n/data then this returns /home/twl8n/data/QSgLKgGJFU
        # perl -e 'use File::Temp qw(tempdir); $tempdir = tempdir ( DIR => "/home/twl8n/data" ); print $tempdir;'

        my $tempdir = tempdir ( DIR => $data_dir );

        (my $input_file, my $dummy) = save_upload_file($qq, # CGI object 
                                                      \%ch, # CGI hash reference
                                                      'input', # file name key in %ch
                                                      $tempdir, # destination dir
                                                      '', # upload type '' for normal text or binary
                                                      0); # use db boolean, false is do not use db

        if (! $input_file)
        {
            $msg .= "Upload or file processing failed. $ch{message}";
            write_log($ch{message});
        }
        else
        {
            my $last_dir = process_xslt($input_file, $tempdir);
            
            my $rec_ref = build_file_list("data/$last_dir");
            if ($rec_ref)
            {
                $template->param(recs => $rec_ref);
            }
            else
            {
                $msg .= "Bad data path: $ch{data_path}\n";
            }
            $template->param(show_dir => 'block');
            
            my $user_dir = real_to_user($tempdir);
            my $user_url = get_url() . "?state=do_dir&data_path=$user_dir";
            
            $template->param(show_temp => 'block');
            $template->param(tempdir => $user_dir);
            $template->param(user_url => $user_url);
        }
    }

    $template->param(msg => $msg);
    my $output = $template->output;
    
    print $orig_stdout "Content-Type: text/html; charset=iso-8859-1\n\n$output";
}

sub sanity_check_environment
{
    my $msg = "";

    if (! -d $cf{data_dir})
    {
        $msg .= "Missing data directory<br>\n";
    }
    if (! -f $cf{find_exe})
    {
        $msg .= "Missing find utility<br>\n";
    }
    if (! -f $cf{chmod_exe})
    {
        $msg .= "Missing chmod utility<br>\n";
    }
    if (! -f $cf{zip_exe})
    {
      $msg .= "Missing zip utility<br>\n";
    }
    if (! -f $cf{yaz_marcdump_exe})
    {
      $msg .= "Missing marcdump utility<br>\n";
    }

    if ($msg)
    {
        print "Content-Type: text/html; charset=iso-8859-1\n\n<html><body>$msg<br>Please contact twl8n\@virginia.edu with this error message.</body></html>";
        exit();
    }
}

sub clean_old_files
{
    # We don't want this to clean up the test.log, but since write_log() updates test.log, it shouldn't be a
    # problem. Use -mindepth 1 so the top level directory is not included.
    
    open(STDOUT, '>>', "$data_dir/test.log");
    open(STDERR, '>&STDOUT');

    # We don't need to clean constantly. So, if it has been more than 7 days since the cleaning semaphore file
    # was touched, run the clean. The point of chmod was that a non-apache user could touch the semaphore file
    # for testing purposes, but it turns out that "touch -d" is restricted to the owner of a file. So... if
    # you remove the semaphore file and decide to create it manually by calling touch, you must also chown the
    # file to apache:apache or apache's touch below will fail. None of this would be an issue if we were
    # running suexec, but we aren't.

    my $last_log_time = (stat("$data_dir/cleaning_semaphore.txt"))[9];
    if (! -e "$data_dir/cleaning_semaphore.txt" || ($last_log_time < (time() - 604800)))
    {
        system("/bin/touch", "$data_dir/cleaning_semaphore.txt");
        system($cf{chmod_exe}, "go+w", "$data_dir/cleaning_semaphore.txt");
        my @cmd = ($cf{find_exe}, $data_dir, '-mindepth',  1, '-mtime', '+7', '-delete');
        write_log("cmd: " . join(' ', @cmd) . " with >> $data_dir/test.log 2>&1");
        system(@cmd);
    }
    else
    {
        system($cf{chmod_exe}, "go+w", "$data_dir/cleaning_semaphore.txt");
        # write_log("Not cleaning");
    }
}


sub exit_to_home
{
    # This is how we jump out of the middle of some processing, finish loading the HTML template, give the
    # user a message, and stop doing everything else. Not all code is using this.

    my $template = $_[0];
    my $msg = $_[1];

    $template->param(msg => $msg);
    my $output = $template->output;
    
    print $orig_stdout "Content-Type: text/html; charset=iso-8859-1\n\n$output";
    exit();
}


sub real_to_user
{
    my $dir = $_[0];
    
    # Remove prefix "$data_root/". Use a temp string because / is easier to read the \/ espeically in a s///
    # regex.
        
    my $match  = "$data_root/";

    $dir =~ s/^$match//;
    return $dir;
}

sub user_to_real
{
    my $dir = $_[0];

    # Add previx "$data_root/"
    
    $dir = "$data_root/$dir";
    return $dir;
}

sub process_xslt
{
    my $input_file = $_[0];

    # $tempdir is a full, absolute path
    my $tempdir = $_[1];

    my $full_data_dir = $data_dir;

    # We need an additional param for oclc_marc2cpf.xsl to control the result-document file name, or at least
    # allow us to add our unique prefix/suffix.

    # use the special permission "X" so only dirs will get "x" (files will not get "x").
    # Indirect call to system() can't use * or other shell meta chars, so use -R and the directory
    
    open(STDOUT, '>>', "./data_dir/test.log");
    open(STDERR, '>&STDOUT');
    system($cf{chmod_exe}, "-R", "+rwX",  "$full_data_dir"); #  >> ./data/test.log 2>&1");

    if ($input_file =~ m/\.mrc$/)
    {
        (my $basename) = fileparse($input_file, ".mrc");
        my @cmd = ($cf{yaz_marcdump_exe},  '-i', 'marc', '-o', 'marcxml', $input_file); 
        write_log("cmd: " . join(' ', @cmd) .  "with > $tempdir/$basename.xml 2>> $full_data_dir/test.log");
        open(STDOUT, '>', "$tempdir/$basename.xml");
        open(STDERR, '>>', "$full_data_dir/test.log");
        system(@cmd);
        $input_file =  "$tempdir/$basename.xml";
        # system("");
    }
    my @cmd = ("$cf{document_root}/saxon.sh", $input_file, "oclc_marc2cpf.xsl", "output_dir=$tempdir");
    
    write_log("cmd: " . join(' ', @cmd) . "with >> $full_data_dir/test.log 2>&1");

    open(STDOUT, ">>", "$full_data_dir/test.log");
    open(STDERR, ">&STDOUT");
    system(@cmd);

    chdir($data_dir);

    # This time the dot stays with the suffix (extension), not the basename.
    (my $basename) = fileparse($input_file, ".xml");

    # Using full, absolute paths would cause the zip archive to create too many levels of directories. Note:
    # the zip command below will zip up all the files in the directory, regardless of their name, extension,
    # whatever. This could pose a risk if the bad guys found a way to get bad files into the user dir.

    my $last_dir = $tempdir;
    $last_dir =~ s/.*\///;

    # Still sending stdout and stderr to $full_data_dir/test.log
    # Remember no shell meta chars so use -r to make zip recurse
    system($cf{zip_exe}, '-r', "$tempdir/$basename.zip", "$last_dir");
    
    chdir("$tempdir");

    # Make the $tempdir g+x and all files g+rw
    # Still sending stdout and stderr to $full_data_dir/test.log 2>&1"
    system($cf{chmod_exe}, '-R', 'ugo+rwX', '.'); 

    # Still sending stdout and stderr to $full_data_dir/test.log 2>&1"
    system("$cf{chmod_exe}",  '-R', 'ugo+rwX', "$full_data_dir");
    return $last_dir;
}

sub trim
{
    my $str = $_[0];
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub write_log
{
    open(my $out, ">>", "$data_dir/test.log") || die "Error: sub write_log can't open log for write: $data_dir/test.log Message: $_[0]\n";
    printf($out "%s: $_[0]\n", scalar(localtime()));
    close($out); 
}


sub build_file_list
{
    my $data_path = $_[0];
    $data_path = user_to_real(untaint($data_path));
    
    # $data_dir is like /home/mst3k/data and $data_root is like /home/mst3k
    
    if (-e $data_path && $data_path =~ m/^$data_dir/)
    {
        # Find *.xml or *.mrc and pipe to sort, ignore case. It would be difficult (awkward) to do this with
        # system() even when redirecting stdout to a variable. There is no data from outside the program here,
        # so this should be secure.

        my @xmlf = `$cf{find_exe} $data_path -name "*.xml" -o -name "*.mrc" | sort -f`;
        chomp(@xmlf);
        my @zipf = `$cf{find_exe} $data_path -name "*.zip"`;
        chomp(@zipf);

        my @files = (@xmlf, @zipf);

        my @recs;
        foreach my $file (@files)
        {
            (my $basename) = fileparse($file);
            my $no_view = 0;
            if ($file =~ m/\.zip$|\.mrc$/i)
            {
                $no_view = 1;
            }
            my %hash = (down_url => sprintf("index.pl?state=get_data&data_path=%s&type=download", real_to_user($file)),
                        data_path => real_to_user($file),
                        view_url => sprintf("index.pl?state=get_data&data_path=%s&type=view", real_to_user($file)),
                        no_view => $no_view,
                        basename => $basename);
            push(@recs, \%hash);
        }
        return \@recs;
    }
    else
    {
        return undef;
    }
}
