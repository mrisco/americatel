#
#       This is Agispeedy Hooks provides a number of "hooks" allowing for
#       servers servers layered on top of Net::Server to respond at 
#       different levels of execution without having to "SUPER" class the 
#       main built-in methods. 
#
#       Current this file your can place hook coding.
#
#       There was may other hooks your can find at 
#       http://search.cpan.org/~rhandom/Net-Server-0.97/lib/Net/Server.pod
#


#
#       configure_hook : This hook takes place immediately after the 
#                        Agispeedy is run.
#
sub configure_hook {

    $self = shift;

    $self->{server}->{port} = $OPT{'HOST'}.':'.$OPT{'PORT'};
    $self->{server}->{user} = $OPT{'USER'};
    $self->{server}->{group} = $OPT{'GROUP'};
    $self->{server}->{min_servers} = $OPT{'MIN_SERVERS'};
    $self->{server}->{min_spare_servers} = $OPT{'MIN_SPARE_SERVERS'};
    $self->{server}->{max_spare_servers} = $OPT{'MAX_SPARE_SERVERS'};
    $self->{server}->{max_servers} = $OPT{'MAX_SERVERS'};
    $self->{server}->{max_requests} = $OPT{'MAX_REQUESTS'};
    $self->{server}->{log_level} = 3;
    $self->{server}->{log_file} = $OPT{'LOG_FILE'};
    $self->{server}->{setsid} = $OPT{'SETSID'};
    $self->{server}->{pid_file} = $OPT{'PID'}.'/'.$OPT{'CFG_MAINNAME'}.'.pid';

    $self->{server}->{check_for_dead} = 16;
    $self->{server}->{check_for_waiting} = 8;


    #------------------------------------------------------------------
    # pid checking
    #------------------------------------------------------------------
    if ($^O eq 'linux' && -e$self->{server}->{pid_file}) {
    my  $pid_number;
        open(READ,$self->{server}->{pid_file}) or die "Can't open pid!";
        read(READ,$pid_number,32);
        close(READ);
        chomp($pid_number);
        
        if (-e"/proc/$pid_number/cmdline" && $pid_number ne $$) {
        my  $pid_cmdline = `cat /proc/$pid_number/cmdline`;
            chomp($pid_cmdline);
            #pid found
            if ($pid_cmdline =~ /$OPT{'CFG_MAINNAME'}/) {
                $self->log(1,"Agispeedy Already running: $pid_number");
                $self->log(1,"Exit...");
                exit;
                #system("kill -9 $pid_number");
                #sleep(1);
                #system("kill $pid_number");
            #pid not this script
            } else {
                unlink($self->{server}->{pid_file});
            }
        
        #pid not exists
        } else {
            unlink($self->{server}->{pid_file});
        }
        #sleep(2);
    }

}


#
#       configure_hook : This hook occurs just after the reading of 
#                        configuration parameters and initiation of logging
#                        and pid_file creation.
#
sub post_configure_hook {
    
    $self->log(1,"Agispeedy $OPT{VERSION} services on...");

    #------------------------------------------------------------------
    # Preload static Agispeedy Modules
    #------------------------------------------------------------------
        # announce static Agispeedy module struction
        our (%STATIC_MODULES,@STATIC_MODULES_LIST);    
    if ($OPT{'AGIMOD_ENABLE_STATIC'}) {

        while (<$OPT{'VAR'}/*.$OPT{'AGIMOD_STATIC_EXT'}>) {
            push(@STATIC_MODULES_LIST,$_);
        }

        foreach (sort @STATIC_MODULES_LIST) {
            next if (!-e$_);
            
            #file register
        my	$scriptname = basename($_);
            $scriptname =~ s/\.(.*)//;

            #load static Agispeedy modules
            do $_;
            if ($@) {
                $self->log(1,"Loading static failed: ".$_."\n".$@);
                exit;
            }

            if (!defined *{$scriptname}{CODE}) {
                $self->log(1,"Loading static failed: No Entry function $mname found!");
                warn "Error function '$mname' Not found in $_\n";
                exit;
            }

            #saving
        my	@filestat = stat($_);
            $STATIC_MODULES{$scriptname} = {
                'path'=>$_,
                'regtime'=>time,
                'filestat'=>\@filestat,
            };

            $self->log(2,"Loading static : ".$scriptname);
        }
    }

    return(1);
}


#       child_init_hook : This hook takes place immediately after the
#                        child process was init. if you want to make fast
#                        database connect, your can write your database handle
#                        followed sub child_init_hook()
#
sub child_init_hook {
    # Parametros de conexion NSOFT - MSSQL    
    my $db_mssql   = 'nsoft-produccion';
    my $dns_mssql  = 'DBI:Sybase:server='.$db_mssql;
    my $user_mssql = 'sa';
    my $pass_mssql = 'rekoll';

    # Parametros de conexion BUN_PERU - MSSQL    
    my $db_bun   = 'bun-produccion';
    my $dns_bun  = 'DBI:Sybase:server='.$db_bun;
    #my $user_bun = 'persefone';
    #my $pass_bun = 'P3rs3f0n3_4Mt3l.1977';
    my $user_bun = 'AMERICATELPERU\sql_ngn';
    my $pass_bun = '4mt3L_tr4f1C0.1977';

    # Parametros de conexion NSOFT - MYSQL
    my $dns_mynsoft  = 'DBI:mysql:nsoft;host=192.168.62.249';
    my $user_mynsoft = 'sistemas';
    my $pass_mynsoft = 's1st3m4s.1977';

    #;# Parametros de conexion BD PORTABLIDAD - MYSQL
    #;my $dns_myporta  = 'DBI:mysql:portabilidad;host=192.168.62.90';
    #;my $user_myporta = 'sistemas';
    #;my $pass_myporta = 's1st3m4s.1977';
    #;#my $dns_myporta  = 'DBI:mysql:portabilidad;host=apolo.americatelperu.red';
    #;#my $user_myporta = 'portabilidad';
    #;#my $pass_myporta = 'P0rt4b1l1D4d_4mT3l.1977';
    
    # Parametros de conexion BD PORTABLIDAD - MSSQL
    my $dbp_mssql   = 'portabilidad';
    my $dnsp_mssql  = 'DBI:Sybase:server='.$dbp_mssql;
    my $userp_mssql = 'portabilidad';
    my $passp_mssql = 'p0RT4b1L1d4d_4mT3l.1977';

    if (!defined $self->{server}{dbh} || !$self->{server}{dbh}->ping) {
       $self->{server}{dbh} = DBI->connect($dns_mssql, $user_mssql, $pass_mssql, {'RaiseError' => 1});
       $self->log(2, "Database $db_mssql  Connected!");
    }

    if (!defined $self->{server}{dba} || !$self->{server}{dba}->ping) {
       $self->{server}{dba} = DBI->connect($dns_mssql, $user_mssql, $pass_mssql, {'RaiseError' => 1});
       $self->log(2, "Database $db_mssql  Connected!");
    }

    if (!defined $self->{server}{dbb} || !$self->{server}{dbb}->ping) {
       $self->{server}{dbb} = DBI->connect($dns_mssql, $user_mssql, $pass_mssql, {'RaiseError' => 1});
       $self->log(2, "Database $db_mssql  Connected!");
    }

    if (!defined $self->{server}{dbbun} || !$self->{server}{dbbun}->ping) {
       $self->{server}{dbbun} = DBI->connect($dns_bun, $user_bun, $pass_bun, {'RaiseError' => 1});
       $self->log(2, "Database $db_bun nsoft Connected!");
    }

    if (!defined $self->{server}{dbmynsoft} || !$self->{server}{dbmynsoft}->ping) {
       $self->{server}{dbmynsoft} = DBI->connect($dns_mynsoft, $user_mynsoft, $pass_mynsoft, {'RaiseError' => 1});
       $self->log(2, "Database mysql nsoft Connected!");
    }

    #;if (!defined $self->{server}{dbmyporta} || !$self->{server}{dbmyporta}->ping) {
    #;   $self->{server}{dbmyporta} = DBI->connect($dns_myporta, $user_myporta, $pass_myporta, {'RaiseError' => 1});
    #;   $self->log(2, "Database mysql porta Connected!");
    #;}

    if (!defined $self->{server}{dbp} || !$self->{server}{dbp}->ping) {
       $self->{server}{dbp} = DBI->connect($dnsp_mssql, $userp_mssql, $passp_mssql, {'RaiseError' => 1});
       $self->log(2, "Database $dbp_mssql Connected!");
    }
}

1;
