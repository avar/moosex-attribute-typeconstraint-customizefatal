use strict;
use warnings;
use Test::More tests => 21;
use Try::Tiny;

{
    package Class;
    use Moose;
    use MooseX::Types::Moose ':all';
    use MooseX::Attribute::TypeConstraint::CustomizeFatal;

    my %attributes = (
        a => "warning",
        b => "default",
        c => "default_no_warning",
        d => "error",
    );

    while (my ($attribute, $on_typeconstraint_failure) = each %attributes) {
        has $attribute => (
            is                        => 'ro',
            isa                       => Int,
            default                   => int rand 2 == 0 ? 12345 : sub { 12345 },

            traits                    => ['TypeConstraint::CustomizeFatal'],
            on_typeconstraint_failure => $on_typeconstraint_failure,
        );
    }

    1;
}

{
    package ImmutableClass;
    our @ISA = ('Class');
    __PACKAGE__->meta->make_immutable;
}

{
    package RwClass;
    use Moose;
    use MooseX::Types::Moose ':all';
    use MooseX::Attribute::TypeConstraint::CustomizeFatal;

    my %attributes = (
        a => "warning",
        b => "default",
        c => "default_no_warning",
        d => "error",
    );

    while (my ($attribute, $on_typeconstraint_failure) = each %attributes) {
        has $attribute => (
            is                        => 'rw',
            isa                       => Int,
            default                   => 12345,

            traits                    => ['TypeConstraint::CustomizeFatal'],
            on_typeconstraint_failure => $on_typeconstraint_failure,
        );
    }

}

my @tests = (
    # "error"
    sub {
        my ($class) = @_;
        try {
            $class->new( d => "foo" );
        } catch {
            like($_, qr/does not pass the type constraint/, "We got an error");
        };
    },
    # "warning"
    sub {
        my ($class) = @_;
        my ($warning, $obj);
        {
            local $SIG{__WARN__} = sub { $warning .= "@_" };
            $obj = $class->new( a => "foo" );
        }
        like($warning, qr/does not pass the type constraint/, "We got a warning");
        is_deeply(
            {%$obj},
            {
                'a' => 'foo',
                'b' => 12345,
                'c' => 12345,
                'd' => 12345
            },
            "We got an incorrect value with a warning"
        );
    },
    # "default"
    sub {
        my ($class) = @_;
        my ($warning, $obj);
        {
            local $SIG{__WARN__} = sub { $warning .= "@_" };
            $obj = $class->new( b => "foo" );
        }
        like($warning, qr/does not pass the type constraint/, "We got a default");
        is_deeply(
            {%$obj},
            {
                'a' => 12345,
                'b' => 12345,
                'c' => 12345,
                'd' => 12345
            },
            "We got a default value with default"
        );
    },
    # "default_no_warning"
    sub {
        my ($class) = @_;
        my ($warning, $obj);
        {
            local $SIG{__WARN__} = sub { $warning .= "@_" };
            $obj = $class->new( c => "foo" );
        }
        ok((not defined $warning), "We didn't get a warning with default_no_warning");
        is_deeply(
            {%$obj},
            {
                'a' => 12345,
                'b' => 12345,
                'c' => 12345,
                'd' => 12345
            },
            "We got a default value with default"
        );
    },
);

$_->('Class') for @tests;
$_->('ImmutableClass') for @tests;

my @tests_accessor = (
    # "warning"
    sub {
        my ($class) = @_;
        my ($warning, $obj);
        {
            local $SIG{__WARN__} = sub { $warning .= "@_" };
            $obj = $class->new();
            $obj->a('foo');
        }
        like($warning, qr/does not pass the type constraint/, "We got a warning");
        is_deeply(
            {%$obj},
            {
                'a' => 'foo',
                'b' => 12345,
                'c' => 12345,
                'd' => 12345
            },
            "We got an incorrect value with a warning"
        );
    },
    # "default"
    sub {
        my ($class) = @_;
        my $obj;
        try {
            $obj = $class->new();
            $obj->b('foo');
        } catch {
            like($_, qr/does not pass the type constraint/, "We got an exception on using accessor with default");
            TODO: {
                local $TODO = "value is not set to default";
                is_deeply(
                    {%$obj},
                    {
                        'a' => 12345,
                        'b' => 12345,
                        'c' => 12345,
                        'd' => 12345
                    },
                    "We got a default value with default"
                    );
              }
        };
    },
    # "default_no_warning"
    sub {
        my ($class) = @_;
        my $obj;
        try {
            $obj = $class->new();
            $obj->c('foo');
        } catch {
            like($_, qr/does not pass the type constraint/, "We got an exception on using accessor with default_no_warning");
            TODO: {
                local $TODO = "value is not set to default";
                is_deeply(
                    {%$obj},
                    {
                        'a' => 12345,
                        'b' => 12345,
                        'c' => 12345,
                        'd' => 12345
                    },
                    "We got a default value with default_no_warning"
                    );
              }
        };
    },
    # "error"
    sub {
        my ($class) = @_;
        try {
            $class->new();
            $class->d( "foo" );
        } catch {
            like($_, qr/does not pass the type constraint/, "We got an error on accessor");
        };
    },
);

$_->('RwClass') for @tests_accessor;
