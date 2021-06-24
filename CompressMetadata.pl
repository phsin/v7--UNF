#!/usr/bin/perl

#=================================================================================================================
# ������ ��� �������� �������� ���������� �� ������� �������.
# ������ ������ ���� � human-readable �������, �.�. ����������� gcomp �������  �� ���� 2.0.10, ��� ����� --no-parse-dialogs.
#=================================================================================================================
#����� - ����� ������� mailto:adirks@ngs.ru
#
#��� ��������� �������� ��������� ����������� ������������. �� ������
#�������������� � (���) �������������� �� �� �������� GNU Generic Public License.
#
#������ ��������� ���������������� � �������� ��������� ��������, ��
#��� �����-���� ��������, � ��� ����� ��� �������� ����������� ��� ������� ���
#�����-���� ������ ������������ �����.
#
#� ������ ������� �������� �� ���������� ����� ����� ������������ �� ������
#http://www.gnu.org/licenses/gpl.txt ��� � �����
#gnugpl.eng.txt
#
#� ������� ��������� �������� ����� ������������ �� ������
#http://gnu.org.ru/gpl.html ��� � �����
#gnugpl.rus.txt
#
#�� ������ �������� ����� GNU Generic Public License ������ � ������ ���� ���������.
#���� ��� �� ��� - �������� �� ���� ������� (mailto:adirks@ngs.ru , mailto:fe@alterplast.ru) ��� ��������
#Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

use locale;
use strict "vars";
use vars qw/ $usage
	$root_dir $quiet
	$mdp_begin /;

$usage = <<EOF
����������: ��� ������� ������� ������� �������� ���������� � ����������, ��� ����� ����������� �������� ����� �������� ����������.

�������������:
   perl CompressMetadata.pl [���������]
   
��������� ����� ����:
   -h        - ���� �����
   -d, --dir <dir>  - �������, ������ ������� ����� ����������������� ������� �������. �� ��������� ����� ���������� �
               �������� ��������.
	-q, --quiet		 - ���������� �����			
EOF
;
	
#default values
$root_dir = ".";
$quiet = "";

#command line args processing
use Getopt::Long;
GetOptions(
	"dir|d=s" => \$root_dir,
	"quiet|q" => \$quiet,
) 
	or die w2d($usage);
	
$mdp_begin = <<EOF
Main Metadata Stream: 
{
	MainDataContDef: 
	{
		������: 10009
	}
	�������� ������: 
	{
		{
		}
	}
EOF
;

#print w2d("ROOT: $root_dir\n");
#traverse through dirs and do work
use File::Find; #package ��� ������������ ������ ���������
find(\&TruncateMetadata, $root_dir);

sub TruncateMetadata
{
	my $name = $_; #File::Find ���������� � $_ ��� �������� �����
	return unless $name =~ m/^(.*)(\���������.mdp)$/i; #��� ����� ������ ���������, ��� ���� ����������
	open IDS, "< �����������������.txt" or return;
	close IDS;
	
	my $line;
	my @FullTypes;

	#������ ��� ������ �� ���������� �� �������
	$name = "�����.frm";
	open DLG, "< $name" or return; #��� ����� - ������ ������������
	foreach $line (<DLG>)
	{
		#���������� ���: ��������.��������������
		if( $line =~ m/^\s*���������� ���:\s*(.*)$/ )
		{
			push(@FullTypes, $1) if InArr($1, @FullTypes) == 0;
		}
	}
	close DLG;
	
	print w2d("Compressing MD: $File::Find::dir\n") unless $quiet;
	
	##################################################################################
	#������������ �����  <���������.mdp>
	##################################################################################
	@FullTypes = sort {str_cmp($a, $b)} @FullTypes;
	my @Types;
	my ($full_type, $type, $kind);
	my $buh_params = BuhParams(\@FullTypes);
	open MDP_NEW, "> ���������.mdp" or print w2d("Can't move <���������.new.mdp> to <���������.mdp>: $!\n");
	printf MDP_NEW "%s\n", $mdp_begin;
	
	#���������� �� ���� �����, � ��������� ��������������� ������� � ����� ����������
	foreach $full_type (@FullTypes)
	{
		$full_type =~ m/(\w+)\.(\w+)/ or next;
		$type = $1;
		$kind = $2;
		
		next if $type =~ m/�����������/;
		next unless $kind;
		
		if( $type =~ m/������������/ ) {$type = "������������";}
		elsif( $type =~ m/��������/ ) {$type = "���������";}
		elsif( $type =~ m/����������/ ) {$type = "�����������";}
		
		if( InArr($type, @Types) == 0 )
		{
			printf MDP_NEW "\t}\n" if $#Types >= 0;
			push(@Types, $type);
			printf MDP_NEW "\t$type:\n\t{\n";
		}
		
		if( InArr($full_type, @Types) == 0 )
		{
			printf MDP_NEW "\t\t$kind:\n\t\t{\n\t\t}\n\n";
			push @Types, $full_type;
		}
	}
	
	#����������� ������
	printf MDP_NEW "\t}\n" if $#Types >= 0;
	# ... � ��������� �����������
	printf MDP_NEW "$buh_params";
	#printf MDP_NEW "}\n";
	close MDP_NEW;

	##################################################################################
	#������������ �����  <�����������������.txt>
	##################################################################################
	
	########    �������������, ������� ���� ��������� � ����� ������   ####################################
	push(@FullTypes, "������");
	push(@FullTypes, "����������.������");
	#################################################################################
	my @IDSused;
	my $nIDsSkipped = 0;
	
	open IDS, "< �����������������.txt" or return;
	foreach $line (<IDS>)
	{
		$line =~ s/[\r\n]//g; #����� ����������� \n � \r, ���� ��� ��� ����
		$line =~ m/^\s*(\d+)\s+(([^\.\s]+)([^\s]*))\s*$/;
		my $full_type_file = $2;
		
		my $ID_used = 0;
		if( $3 eq "�����������" )
		{
			$ID_used = 1;
		}
		else
		{
			foreach $full_type (@FullTypes)
			{
				if( $full_type eq $full_type_file )
				{
					$ID_used = 1;
					last;
				}
			}
		}
		
		if( $ID_used == 1 )
		{
			push( @IDSused, $line );
		}
		else
		{
			$nIDsSkipped++;
		}
	}
	close IDS;
	
	#return if $nIDsSkipped == 0; #������� ��� ���������
	
	@IDSused = sort @IDSused;
	
	open IDS_NEW, "> �����������������.txt" or print w2d("Can't move <�����������������.new.txt> to <�����������������.txt>: $!\n");
	foreach $line (@IDSused)
	{
		printf IDS_NEW "$line\n";
	}
	close IDS_NEW;
}

sub BuhParams
{
	my $Types = shift;
	my $line;
	my $buh_params = "";
	my $started = 0;
	
	open MDP, "< ���������.mdp" or return "";
	foreach $line (<MDP>)
	{
		$started = 1 if $line =~ m/^\s*��������� �����������:\s*$/;
		if( $started )
		{
			$buh_params .= $line;
			if( $line =~ m/^.*\s+����������\.([^\s]+)\s*$/ )
			{
				push @$Types, "����������.$1";
			}
		}
	}
	close MDP;
	
	$buh_params = "}\n" if length $buh_params == 0;
	
	return $buh_params;
}

sub InArr
{
	my $what = shift;
	my @arr = @_;
	my $val;
	foreach $val (@arr)
	{
		return 1 if $val eq $what;
	}
	return 0;
}

sub str_cmp($$)
{
	my $left = shift;
	my $right = shift;
	if( $left le $right ) {return -1;}
	if( $left gt $right ) {return 1;}
	return 0;
}

sub w2d {
	my $win_chars = "\xA8\xB8\xB9\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF";
	my $dos_chars = "\xF0\xF1\xFC\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF";
	$_ = shift;
	return $_ if $^O eq "cygwin";
	eval("tr/$win_chars/$dos_chars/");
	return $_;
}
