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
    # Parametros de conexion BD PORTABLIDAD - MSSQL
    my $db_mssql   = 'portabilidad';
    my $dns_mssql  = 'DBI:Sybase:server='.$db_mssql;
    my $user_mssql = 'portabilidad';
    my $pass_mssql = 'p0RT4b1L1d4d_4mT3l.1977';

	# Parametros de conexion BD NGN - MSSQL
    my $db_ngn  = 'ngn';
    my $dns_ngn  = 'DBI:Sybase:server='.$db_ngn;
    my $user_ngn = 'AMERICATELPERU\sql_ngn';
    my $pass_ngn = '4mt3L_tr4f1C0.1977';
    
    if (!defined $self->{server}{dbh} || !$self->{server}{dbh}->ping) {
       $self->{server}{dbh} = DBI->connect($dns_mssql, $user_mssql, $pass_mssql, {'RaiseError' => 1});
       $self->log(2, "Database $db_mssql Connected!");
    }

    if (!defined $self->{server}{dbn} || !$self->{server}{dbn}->ping) {
       $self->{server}{dbn} = DBI->connect($dns_ngn, $user_ngn, $pass_ngn, {'RaiseError' => 1});
       $self->log(2, "Database $db_ngn Connected!");
    }
}

1;
