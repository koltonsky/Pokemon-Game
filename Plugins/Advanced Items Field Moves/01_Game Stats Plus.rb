#===============================================================================
# Additional Game Stats
#===============================================================================
class GameStats < GameStats
  attr_accessor :dig_count
  attr_accessor :dive_ascend_count
  attr_accessor :sweetscent_count
  attr_accessor :teleport_count
  attr_accessor :whirlpool_cross_count
  attr_accessor :rockclimb_ascend_count
  attr_accessor :rockclimb_descend_count
  attr_accessor :ice_smash_count
  attr_accessor :temp_count

  alias advanceditemsfieldmoves_init initialize
  def initialize
    advanceditemsfieldmoves_init
    @dig_count                     = 0
    @dive_ascend_count             = 0
    @sweetscent_count              = 0
    @teleport_count                = 0
    @whirlpool_cross_count         = 0
    @rockclimb_ascend_count        = 0
    @rockclimb_descend_count       = 0
    @ice_smash_count               = 0
    @temp_count                    = 0
  end
end


#===============================================================================
# Fixes Stats Reset on new game
#===============================================================================
module Game
  def self.start_new
    if $game_map&.events
      $game_map.events.each_value { |event| event.clear_starting }
    end
    $game_temp.common_event_id = 0 if $game_temp
    $game_temp.begun_new_game = true
    $scene = Scene_Map.new
    SaveData.load_new_game_values
    $stats.initialize #Reset Stats on starting new game // Only save if you save the game
    $stats.play_sessions += 1
    $map_factory = PokemonMapFactory.new($data_system.start_map_id)
    $game_player.moveto($data_system.start_x, $data_system.start_y)
    $game_player.refresh
    $PokemonEncounters = PokemonEncounters.new
    $PokemonEncounters.setup($game_map.map_id)
    $game_map.autoplay
    $game_map.update
  end
end

def showStats
  id = "Dick"
  pbMessage(_INTL("You have {1} in {2} stats!", $stats.temp_count, id))
end
