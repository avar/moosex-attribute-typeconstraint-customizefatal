use strict;
use warnings;
use Test::More tests => 7;
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
            default                   => 12345,

            traits                    => ['TypeConstraint::CustomizeFatal'],
            on_typeconstraint_failure => $on_typeconstraint_failure,
        );
    }

}

# "error"
{
    try {
        Class->new( d => "foo" );
    } catch {
        like($_, qr/does not pass the type constraint/, "We got an error");
    };
}

# "warning"
{
    my ($warning, $obj);
    {
        local $SIG{__WARN__} = sub { $warning .= "@_" };
        $obj = Class->new( a => "foo" );
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
}

# "default"
{
    my ($warning, $obj);
    {
        local $SIG{__WARN__} = sub { $warning .= "@_" };
        $obj = Class->new( b => "foo" );
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
        "We got an default value with default"
    );
}

# "default_no_warning"
{
    my ($warning, $obj);
    {
        local $SIG{__WARN__} = sub { $warning .= "@_" };
        $obj = Class->new( c => "foo" );
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
        "We got an default value with default"
    );
}
