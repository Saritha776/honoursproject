package JSON; sub new { bless {}, shift; } sub allow_nonref { shift; } sub pretty { shift; } sub encode { return '{}'; } 1;
