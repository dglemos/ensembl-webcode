#!/usr/local/bin/perl

# Script for dumping the mysql files for the release (run perl dump.pl 60)
# Can be run for specific databasename, table name.
# db= is for databasename (one at a time no comma separated list allowed)
# table= is for tablename, can be a list of comma separated tablenames (no space) and should specify databasename (db=) for this to work
# ex: perl dump.pl 60 db=ensembl_mart table=meta_conf__user__dm,meta_template__template__main
#
# Also Allowing script to be run for different hostname (one connection at a time ).
# hostname= is for the hostname of the database server (one hostname at a time)
# port= is for port number to listen to on the database server
# username= is for username to login on the database server
# pass= is for the password for the database server


use strict;
use Time::HiRes qw(time);
# use constant MAX => 2 * 1024 * 1024 * 1024;
use constant MAX => 1024 * 1024 * 1024;
use DBI;

my $VERSION = shift @ARGV; #release version should always be the first argument when running the script

my ($arg,$db,$table_name,$hostname,$PORT,$USER,$PASS);
foreach my $row (@ARGV)
{
  $row =~ s/,/|/g if($row =~ /table/i);                         #only argv table are allowed to have comma separated list
  ($arg,$db)        = split(/=/,$row) if($row =~ /db=/i);       #splitting ARGV db for different database name
  ($arg,$table_name)= split(/=/,$row) if($row =~ /table/i);     #splitting ARGV table for different table name 
  ($arg,$hostname)  = split(/=/,$row) if($row =~ /hostname/i);
  ($arg,$PORT)      = split(/=/,$row) if($row =~ /port/i);
  ($arg,$USER)      = split(/=/,$row) if($row =~ /username/i);
  ($arg,$PASS)      = split(/=/,$row) if($row =~ /pass/i);
  
}
if($table_name && !$db){
  print "[ERROR]No database specified!!! include db= when running the script for specific table.\n\n";
  exit;
}

my $dumps_dir    = '/mysql/dumps';
my $sub_dir      = "release-$VERSION";
mkdir "$dumps_dir/$sub_dir";
#my $hostname = `hostname`;

our $ST = time;
chomp $hostname;
open( LH, ">$hostname.log" );


my $C = "/usr/local/ensembl/mysql/bin/mysql -h$hostname -P$PORT -u$USER -p$PASS -e 'show databases'";
my @databases = `/usr/local/ensembl/mysql/bin/mysql -h$hostname -P$PORT -u$USER -p$PASS -e 'show databases'`; 
shift(@databases);
if($db && !grep(/^($db)$/, @databases)){
  print "[ERROR]Could not find database::$db on server::$hostname!!! \n";
  exit;
}

foreach my $db_name ( @databases ) {
  chomp($db_name);
  if($db){
    next if($db_name !~ /$db/);
    log_msg("[INFO]Dumping whole database::$db") if(!$table_name);
  }
  log_msg( $db_name );
  my $dbh = DBI->connect("dbi:mysql:$db_name:$hostname:$PORT",$USER,$PASS);
  my $DIR = "$dumps_dir/$sub_dir/$db_name";
  my $SQL = '';
 
  system( "rm -r $dumps_dir/$sub_dir/$db_name")  if($db && !$table_name);  
  system( "mkdir $DIR" );
  system( "chmod 777 $DIR");
  chdir( $DIR );  
  my @tables = map {@$_} @{$dbh->selectall_arrayref('show tables')};

  #check if table exist when running script for specific tables
  if($table_name){
    foreach my $each_table (split(/\|/,$table_name)){
      log_msg("[WARN]Could not find table::$each_table in database::$db!!!") if(!grep(/^($each_table)$/,@tables));
    }
  }

  foreach my $table (@tables) {
    if($table_name && $db){
      next if($table !~ /$table_name/);
      log_msg("[INFO]Dumping table::$table from database::$db");
    }
    system("rm $DIR/$table.txt.gz") if($table_name);   #got to remove the old file first 
    my $FN = "$DIR/$table.txt";
    log_msg( " |- dumping $table" );
    my($M,$T)=$dbh->selectrow_array("show create table $table;" );
    $SQL .= "$T;\n\n";
    $dbh->do( "select * into outfile '$FN' FIELDS ESCAPED BY '\\\\' from $table" );
    log_msg( " `- zip $table (".(-s $FN).')' );
    system( "gzip -9 -f $FN" );
  }
  
  #only do this when dumping whole database
  if(!$db && !$table_name){
    open O,">$db_name.sql";
    print O $SQL;
    close O;
  }
  log_msg( "  Computing checksums" );
  system "gzip -9 -f $db_name.sql"  if(!$db && !$table_name);
  system "rm CHECKSUMS.gz" if($db && $table_name);
  system "sum *.sql.gz *.txt.gz > CHECKSUMS";
  system "gzip -9 -f CHECKSUMS";
  log_msg( "  finished" );
}

close LH;

sub log_msg {
  printf LH "%10.3f %s\n", time-$ST, join ' ', @_;
}

1;
