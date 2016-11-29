=pod
Полностью закачка или обновление дельты

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

use strict;
use utf8;
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

#~ use LWP::UserAgent;
use LWP::UserAgent::ProgressBar;
#~ use XML::Parser;
use XML::Twig;
use DBI;
use Getopt::Long;
use Data::Dumper;
#~ my $ua = LWP::UserAgent->new;
my $ua = LWP::UserAgent::ProgressBar->new;
$ua->agent('');

#~ my $BASE = '';
my %opt = (
	url => 'http://fias.nalog.ru/WebServices/Public/DownloadService.asmx',#http://fias.nalog.ru/WebServices/Public/DownloadService.asmx
	table => 'AS_ADDROBJ',
	dbname => 'fias',
	dbhost => '192.168.1.4',
	dblogin => 'perl',
	dbpasswd => undef,
	debug=>1,
	xmlfile=>undef, # для полной закачки вручную скачать, распокавать и указать AS_ADDROBJ_20140601_f78af112-09a4-4a17-9eb2-3c40f45e402e.XML
	complete=>undef,# или флажок для полной версии
	nosave=>0,
	sqldump=>0,
);
GetOptions(
	(map {$_.'=s' => \$opt{$_};} keys %opt),
);

print Dumper(\%opt) if $opt{debug};

my $dbh = DBI->connect("DBI:mysql:database=$opt{dbname};host=$opt{dbhost};", $opt{dblogin}, $opt{dbpasswd}, {
		ShowErrorStatement => 1,
		AutoCommit => 0,
		RaiseError => 1,
		PrintError => 0, 
		mysql_enable_utf8 => 1,}) or die;
my $config = $dbh->selectall_hashref(<<END_SQL, 'key', undef, ('update_%'));
select * from `config`
where `key` like ?;
END_SQL
#~ my $versionid = do {
	#~ open my $fh, '<', 'versionid.txt';
	#~ my $v = (<$fh> =~ /(\d+)/)[0];
	#~ close $fh;
#~ };
my ($fiasdeltaxmlurl, $fiascompletexmlurl);
my $twig= XML::Twig->new(
	twig_roots => {
		'TextVersion'=>sub {my( $t, $elt)= @_; $config->{update_textversion} = $elt->text; $t->purge;},
		'VersionId'=>sub {my( $t, $elt)= @_; die "Версия [@{[$elt->text]}] обновления не новая! Выход." if $config->{update_versionid}{value} eq $elt->text; $config->{update_versionid} = $elt->text; $t->purge;},#print $versionid, "\n";
		'FiasDeltaXmlUrl'=>sub{my( $t, $elt)= @_; $fiasdeltaxmlurl = $elt->text; $t->purge;},
		'FiasCompleteXmlUrl'=>sub{my( $t, $elt)= @_; $fiascompletexmlurl = $elt->text; $t->purge;},
		#~ FiasCompleteXmlUrl=>sub{my( $t, $elt)= @_; print Dumper($elt), "\n"; $t->purge;},
		"AddressObjects/Object"=>sub {# основной парсинг
			my( $t, $elt)= @_;
			if ( $opt{debug} > 1) {$elt->print; print "\n";}
			
			my $r = $elt->atts;# Return a hash ref containing the element attributes
			if (grep(defined $r->{$_} && length($r->{$_}) != 36, qw(AOID AOGUID PARENTGUID))) {warn "\nОшибка парсинга!! Длина ИДа != 36  ", Dumper($r) , $elt->print;}
			elsif (!$opt{nosave}) {insert_or_replace($r);}
			$t->purge;
			#~ print ".";
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
print Dumper($post->request),"\n", $post->decoded_content, "\n\n" if $opt{debug};

$twig->parse($post->decoded_content);
#~ exit;

my $url = $opt{complete} ? $fiascompletexmlurl : $fiasdeltaxmlurl;
die "Не смог url обновления (SOAP запрос)" unless $url;

#~ print Dumper($config); exit;
print "Загружается Fias@{[$opt{complete} ? 'Complete' : 'Delta']}XmlUrl = [$url] =>>> 'fias_xml.rar'...\n"  if $opt{debug};

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

map {# сохранить версию
	$dbh->do(<<END_SQL, undef, ($_, $config->{$_}, $_, $config->{$_},));
insert into `config` (`key`, `value`) values (?,?)
ON DUPLICATE KEY UPDATE
`key` = ?, `value` = ?;
END_SQL
	
} keys %$config;

system('rm -f AS_*.XML; rm -f fias_xml.rar');

my %index = (
	AOLEVEL=>'AOLEVEL',
	AOGUID =>'AOGUID',
	PARENTGUID => 'PARENTGUID',
	ACTSTATUS => 'ACTSTATUS',
	REGIONCODE => 'REGIONCODE',
	REGLEVFN => [qw(FORMALNAME AOLEVEL REGIONCODE)],
	LIVESTATUS => 'LIVESTATUS',
	code =>'CODE',
	FTFORMALNAME => 'FORMALNAME',# FULLTEXT
);
###################################### SUB ##########################################################################
sub process {
	my $xmlfile = shift || glob 'AS_ADDROBJ*.XML';
	#~ $dbh->begin_work;
	if ($opt{complete}) {
		print "Чикаются все записи $opt{table} и индексы";
		$dbh->do(<<END_SQL,);
delete from `$opt{table}`;
END_SQL
		map {print "Удаляется индекс $_ ..."; $dbh->do(<<END_SQL,); print "OK\n";} keys %index;
alter table `$opt{table}` drop index `$_`;
END_SQL
	}
	print "Обрабатывается файл [$xmlfile]\n"  if $opt{debug};
	$twig->parsefile($xmlfile);#"AS_ADDROBJ_20130110_0deec9c3-21a8-4510-99f6-c85206f140cd.XML"
	if ($opt{complete}) {
		map {
			print "Долго [~2-3 минуты] создается индекс $_ ...";
			$dbh->do(<<END_SQL,);
alter table `$opt{table}` add @{[/^FT/ && 'FULLTEXT']} index `$_` (`@{[ref($index{$_}) ? join('`, `', @{$index{$_}}) : $index{$_}]}`);
END_SQL
			print "OK\n";
		} keys %index;
		#~ print "Долго создается индекс FULLTEXT `FTFORMALNAME ...";
		#~ $dbh->do(<<END_SQL,);
#~ ALTER TABLE `$opt{table}` ADD FULLTEXT `FTFORMALNAME` (`FORMALNAME`);
#~ END_SQL
	}
	$dbh->commit;
	print "===== ====== ====== ГОТОВО ====== ======= ======= \n";

#~ 
	1;
}

my $sth;
my $count = 0;
sub insert_or_replace {
	my $r = shift;
	my @cols = sort keys %$r;
	#~ return if $sth;
	my $c = scalar @cols;
	#~ print "COLS $c\n";
	my $sql  = <<END_SQL;
insert into $opt{dbname}.`$opt{table}` (`@{[join("`,`", @cols)]}`) values (@{[join(',', map('?', @cols))]})
ON DUPLICATE KEY UPDATE
#AOID=AOID
@{[join(', ', map {"`$_`=?"} @cols)]}
;
END_SQL
	if ($opt{sqldump}) {
		$sql =~ s/\?/'%s'/g;
		print sprintf($sql, map {$r->{$_}} (@cols,@cols)), "\n\n";#@cols,@cols
		return 1;
	}
	$sth->{$sql} ||= $dbh->prepare($sql);
	my $rc = $sth->{$sql}->execute(map {$r->{$_}} (@cols,@cols));#@cols,@cols
	$count++;
	print "Обработана строка [#$count] в таблицу [$opt{table}]", $rc, "\n" if $opt{debug};
}

#~ $ mojo get -M POST -H 'Content-Type: application/soap+xml; charset=utf-8' -c '<?xml version="1.0" encoding="utf-8"?><soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope"><soap12:Body><GetLastDownloadFileInfo xmlns="http://fias.nalog.ru/WebServices/Public/DownloadService.asmx" /></soap12:Body></soap12:Envelope>' fias.nalog.ru/WebServices/Public/DownloadService.asmx

#~ $ perl -w -MXML::Twig -e 'binmode(STDOUT, ":utf8"); XML::Twig->new(twig_roots   => {"Object"=>sub{my( $t, $elt)= @_; $elt->print; print "\n"; $t->purge;}})->parsefile("AS_ADDROBJ_20130110_0deec9c3-21a8-4510-99f6-c85206f140cd.XML");'

__END__

    Добавляем расширение для работы с триграммами
    CREATE EXTENSION pg_trgm;
    Создаем индекс на нужном поле
    CREATE INDEX addrobj_formalname_idx ON addrobj USING gist (formalname gist_trgm_ops);
    Теперь ищем
    select * from addrobj where formalname ~ 'ростов';

Всё ура!, теперь поиск происходит за пол секунды

