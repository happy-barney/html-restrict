requires "Carp" => "0";
requires "Data::Dump" => "0";
requires "HTML::Entities" => "0";
requires "HTML::Parser" => "0";
requires "List::Util" => "1.33";
requires "Moo" => "1.002000";
requires "Scalar::Util" => "0";
requires "Sub::Quote" => "0";
requires "Types::Standard" => "1.000001";
requires "URI" => "0";
requires "namespace::clean" => "0";
requires "perl" => "5.006";
requires "strict" => "0";

on 'test' => sub {
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "perl" => "5.006";
  requires "warnings" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::More" => "0.88";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
};
