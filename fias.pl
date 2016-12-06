=pod
Полностью закачка или обновление дельты

http://fias.nalog.ru/Updates.aspx

Полностью:
=========
Запрос
POST /WebServices/Public/DownloadService.asmx HTTP/1.1
Host: fias.nalog.ru
Content-Type: application/soap+xml; charset=utf-8
Content-Length: length

<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <GetAllDownloadFileInfo xmlns="http://fias.nalog.ru/WebServices/Public/DownloadService.asmx" />
  </soap12:Body>
</soap12:Envelope>

Ответе найти нужную версию, ее урл, скачать распаковать
Нужен только файл AS_ADDROBJ*.XML
Запустить:
---------------
perl fias.pl --complete=1 # 
perl fias.pl --xmlfile=AS_ADDROBJ_20140601_f78af112-09a4-4a17-9eb2-3c40f45e402e.XML # вручную файл

Обновление
==========
perl fias.pl



=cut

#~ use strict;
#~ use utf8;
use Mojo::Base::Che -base, -lib, "../lib";
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

#~ use LWP::UserAgent;
use LWP::UserAgent::ProgressBar;
#~ use XML::Parser;
use XML::Twig;
use Mojo::Pg::Che;
use Getopt::Long;
use Data::Dumper;
use Model::Base;
#~ my $ua = LWP::UserAgent->new;
my $ua = LWP::UserAgent::ProgressBar->new;
$ua->agent('ELK');



my %opt = (
  url => 'http://fias.nalog.ru/WebServices/Public/DownloadService.asmx',#http://fias.nalog.ru/WebServices/Public/DownloadService.asmx
  schema => 'fias',
  table => 'AddressObjects',
  #~ config_table => 'config',
  dbname => 'test',
  dbhost => '127.0.0.1',
  dblogin => 'postgres',
  dbpasswd => undef,
  debug=>1,
  xmlfile=>undef, # для полной закачки вручную скачать, распокавать и указать AS_ADDROBJ_20140601_f78af112-09a4-4a17-9eb2-3c40f45e402e.XML
  complete=>undef,# или флажок для полной версии
  #~ nosave=>0,
  #~ sqldump=>0,
);
GetOptions(
  (map {$_.'=s' => \$opt{$_};} keys %opt),
);

say Dumper(\%opt) if $opt{debug};

my $dbh = Mojo::Pg::Che->connect("DBI:Pg:dbname=$opt{dbname};host=$opt{dbhost}", $opt{dblogin}, $opt{dbpasswd})->max_connections(70)
  or die;
my $model = Model::Base->singleton(dbh=>$dbh, template_vars=>{}, mt=>{tag_start=>'{%', tag_end=>'%}'})->sth_cached(1);
#~ my $config = $dbh->selectall_hashref(<<END_SQL, 'key', undef, ('^update_'));
#~ select * from "$opt{schema}"."$opt{config_table}"
#~ where key ~ ?;
#~ END_SQL
my $now = do {#~ my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
  my @lt =  localtime(time);
  sprintf("%s.%s.%s", $lt[3], $lt[4]+1, $lt[5]+1900);
};
my $version = $model->_select($opt{schema}, $opt{table}, ["AOGUID"], {AOGUID=>'00000000-0000-0000-0000-000000000000'}) {
  map(($_ => '00000000-0000-0000-0000-000000000000'), qw(AOGUID AOID)),
  SHORTNAME=>'', # номер версии
  #~ FORMALNAME => '', # текст версии
  UPDATEDATE => $now, # дата обновления
  STARTDATE => $now,
  #~ ENDDATE => # дата версии
  map(($_=>'') , qw(REGIONCODE AUTOCODE AREACODE CITYCODE CTARCODE PLACECODE EXTRCODE SEXTCODE) ),
  map(($_=>0) , qw(AOLEVEL ACTSTATUS CENTSTATUS OPERSTATUS CURRSTATUS LIVESTATUS) ),
};

  

my ($fiasdeltaxmlurl, $fiascompletexmlurl);
my $twig= XML::Twig->new(
  twig_roots => {
    'TextVersion'=>sub {
        my( $t, $elt)= @_;
        #~ $config->{update_textversion} = $elt->text;
        $version->{FORMALNAME} = $elt->text;
        $version->{ENDDATE} = ($elt->text =~ /(\d+\.\d+\.\d+)/)[0];
        $version->{UPDATEDATE} = $now;
        $t->purge;},
    'VersionId'=>sub {
        my( $t, $elt)= @_;
        die "Версия [@{[$elt->text]}] обновления не новая! Выход."
          #~ if $config->{update_versionid}{value} eq $elt->text;
          if $version->{SHORTNAME} eq $elt->text;
        #~ $config->{update_versionid} = $elt->text;
        $version->{SHORTNAME} = $elt->text;
        $t->purge;
      },#say $versionid;
    'FiasDeltaXmlUrl'=>sub {
        my( $t, $elt)= @_;
        $fiasdeltaxmlurl = $elt->text;
        $t->purge;
      },
    'FiasCompleteXmlUrl'=>sub {
        my( $t, $elt)= @_;
        $fiascompletexmlurl = $elt->text;
        $t->purge;
      },
    #~ FiasCompleteXmlUrl=>sub{my( $t, $elt)= @_; say Dumper($elt), "\n"; $t->purge;},
    'AddressObjects/Object'=>sub {# основной парсинг
      my( $t, $elt)= @_;
      if ( $opt{debug} > 1) {$elt->print; say "\n";}
      
      my $r = $elt->atts;# Return a hash ref containing the element attributes
      if ( grep(defined $r->{$_} && length($r->{$_}) != 36, qw(AOID AOGUID PARENTGUID)) ) {
        warn "\nОшибка парсинга!! Длина ИДа != 36  ", Dumper($r) , $elt->print;
      }
      elsif (!$opt{nosave}) {
        insert_or_replace($r);
      }
      $t->purge;
    },
  },
);

process($opt{xmlfile})
  and exit
  if $opt{xmlfile};

# Получить урл дельты
=pod
qq|<?xml version="1.0" encoding="utf-8"?><soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Body><GetLastDownloadFileInfo xmlns="$opt{url}/" /></soap12:Body></soap12:Envelope>|

# Content для полной версии
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <GetAllDownloadFileInfo xmlns="http://fias.nalog.ru/WebServices/Public/DownloadService.asmx" />
  </soap12:Body>
</soap12:Envelope>
=cut


my $post = $ua->post($opt{url}, Content_Type=> 'application/soap+xml; charset=utf-8',  Content => <<END_CONTENT,
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <GetLastDownloadFileInfo xmlns="$opt{url}" />
  </soap12:Body>
</soap12:Envelope>
END_CONTENT
#
);
say Dumper($post->request),"\n", $post->decoded_content, "\n\n"
  if $opt{debug};

$twig->parse($post->decoded_content);
#~ exit;

my $url = $opt{complete} ? $fiascompletexmlurl : $fiasdeltaxmlurl;
die "Не смог url обновления (SOAP запрос)" unless $url;

#~ say Dumper($config); exit;
say "Загружается Fias@{[$opt{complete} ? 'Complete' : 'Delta']}XmlUrl = [$url] =>>> 'fias_xml.rar'...\n"
  if $opt{debug};

my $get = $ua->get_with_progress($url, ':content_file'=>'fias_xml.rar',);
$get->is_success or die "Не смог [$url]";

#~ 
my $line = grep(/AS_ADDROBJ/, `unrar l fias_xml.rar 2>/dev/null`);
my $xmlfile = ($line =~ /(AS_ADDROBJ[\w\-]+\.xml)/i)[0];

#~ system('rm -f AS_*.XML; unrar e fias_xml.rar');
system("rm -f AS_*.XML; unrar e -n'$xmlfile' fias_xml.rar") == 0
  or die "Не смог unrar e -n'$xmlfile' fias_xml.rar: $!";

#~ my $xmlfile = glob 'AS_ADDROBJ*.XML';

process($xmlfile);

#~ $model->вставить_или_обновить($opt{schema}, $opt{config_table}, ['key'], {key=>$_, value=>$config->{$_}})
  #~ for keys %$config;# сохранить версию
$model->вставить_или_обновить($opt{schema}, $opt{table}, ['AOGUID'], $version);# сохранить версию

system('rm -f AS_*.XML; rm -f fias_xml.rar');

###################################### SUB ##########################################################################
sub process {
  my $xmlfile = shift || glob 'AS_ADDROBJ*.XML';
  say "Обрабатывается файл [$xmlfile]\n"
    if $opt{debug};
  $twig->parsefile($xmlfile);#"AS_ADDROBJ_20130110_0deec9c3-21a8-4510-99f6-c85206f140cd.XML"
  #~ $dbh->commit;
  say "===== ====== ====== ГОТОВО ====== ======= ======= \n";

#~ 
  1;
}

my $count = 0;
#~ my %data = ();# пачка строк
#~ my $n = 0;# размерность пачки строк вставки
sub insert_or_replace {
  my $r = shift;
  
  say sprintf("Обработано строк [%s]", ++$count)
    if $opt{debug};
  
  return
    unless $r->{"ACTSTATUS"};

  #~ $data{$_}[$n] = $r->{$_}
    #~ for keys %$r;
  
  #~ return
    #~ if ++$n < 20;
  
  #~ say Dumper \%data;
  return $model->_insert($opt{schema}, $opt{table}, undef, $r
  #~ \%data, 
  #~ sub {

  #~ },
  ) if $opt{complete};
  #~ $count += $n;
  
  #~ %data = ();
  #~ $n=0;
  
  $model->_try_insert($opt{schema}, $opt{table}, ['AOGUID'], $r)
    || $model->_update_distinct($opt{schema}, $opt{table}, ['AOGUID'], $r)
  ;
  
  
}


#~ $ mojo get -M POST -H 'Content-Type: application/soap+xml; charset=utf-8' -c '<?xml version="1.0" encoding="utf-8"?><soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Body><GetLastDownloadFileInfo xmlns="http://fias.nalog.ru/WebServices/Public/DownloadService.asmx" /></soap12:Body></soap12:Envelope>' fias.nalog.ru/WebServices/Public/DownloadService.asmx

#~ $ perl -w -MXML::Twig -e 'binmode(STDOUT, ":utf8"); XML::Twig->new(twig_roots   => {"Object"=>sub{my( $t, $elt)= @_; $elt->print; print "\n"; $t->purge;}})->parsefile("AS_ADDROBJ_20130110_0deec9c3-21a8-4510-99f6-c85206f140cd.XML");'


