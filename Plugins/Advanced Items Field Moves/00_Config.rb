#===============================================================================
# Configuration
#===============================================================================

# :internal_name    -> has to be an unique name, the name you define for the item in the PBS file
# :active           -> defines if this item should be used, if set to false you do not have to add an item to the PBS  file (example: if you want an item for Rock Smash but not for Cut set active for Cut to false)
#                      if the item is active you will no longer be able to use the corresponding HM Move outside of battle
# :needed_badge     -> the id of the badge required in order to use the item (0 means no badge required)
# :needed_switches  -> the switches that needs to be active in order to use the item (leave the brackets empty for no switch requirement. example: [4,22,77] would mean that the switches 4, 22 and 77 must be active)
# :use_in_debug     -> when true this item can be used in debug regardless of the requirements
# :number_terrain   -> has the number for the giving Terrain Tag

module AdvancedItemsFieldMoves

  ROCKSMASH_CONFIG = {
    :internal_name      => :ROCKSMASHITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  CUT_CONFIG = {
    :internal_name      => :CUTITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  STRENGTH_CONFIG = {
    :internal_name      => :STRENGTHITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  SURF_CONFIG = {
    :internal_name      => :SURFITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  FLY_CONFIG = {
    :internal_name      => :FLYITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  HEADBUTT_CONFIG = {
    :internal_name      => :HEADBUTTITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  FLASH_CONFIG = {
    :internal_name      => :FLASHITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  DIG_CONFIG = {
    :internal_name      => :DIGITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  DIVE_CONFIG = {
    :internal_name      => :DIVEITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  SWEETSCENT_CONFIG = {
    :internal_name      => :SWEETSCENTITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  TELEPORT_CONFIG = {
    :internal_name      => :TELEPORTITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  WATERFALL_CONFIG = {
    :internal_name      => :WATERFALLITEM,
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }

  ROCKCLIMB_CONFIG = {
    :internal_name      => :ROCKCLIMBITEM,    # Default: ROCKCLIMBITEM
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false,             # Default: false
    #TerrainTagNumber
    :number_rockclimb   => 18,                # Default: 18
    :number_rockcrest   => 19,                # Default: 19
    #Animation Number
    :debris_id          => 19,                # Default: 19
    :move_up_id         => 20,                # Default: 20
    :move_down_id       => 23,                # Default: 23
    :dust_id            => 24,                # Default: 24
    :base_rockclimb     => false              # Default: false
  }

  WHIRLPOOL_CONFIG = {
    :internal_name      => :WHIRLPOOLITEM,    # Default: WHIRLPOOLITEM
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false,             # Default: false
    #TerrainTagNumber
    :number_whirlpool   => 20,                # Default: 20
    #Animation Number
    :move_up_id         => 25,                 # Default: 25
    :move_left_id       => 26,                 # Default: 26
    :move_right_id      => 27,                 # Default: 27
    :move_down_id       => 28                  # Default: 28
  }

  ICEBARRIERE_CONFIG = {
    :internal_name      => :ICEBARRIEREITEM,  # Default: ICEBARRIEREITEM
    :active             => true,              # Default: true
    :needed_badge       => 0,                 # Default: 0
    :needed_switches    => [],                # Default: []
    :use_in_debug       => false              # Default: false
  }
end
