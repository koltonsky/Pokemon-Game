#-------------------------------------------------------------------------------
# Sky Battles + Inverse Battles
# Credit: mej71 (original), bo4p5687 (update - 18+)
#
#   If you want to set inverse battles, call: setBattleRule("inverseBattle")
#   If you want to set sky battles, call: setBattleRule("skyBattle")
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
module SkyBattle
  # Store pokemon can't battle (sky mode)
  # Pokemon aren't allowed to participate even though they are flying or have levitate
  # Add new pokemon: ':NAME'
  SkyPokemon = [
		:PIDGEY, :SPEAROW, :FARFETCHD, :DODUO, :DODRIO, :GENGAR, :HOOTHOOT, :NATU,
		:MURKROW, :DELIBIRD, :TAILLOW, :STARLY, :CHATOT, :SHAYMIN, :PIDOVE, :ARCHEN,
		:DUCKLETT, :RUFFLET, :VULLABY, :FLETCHLING, :HAWLUCHA
  ]
  
	# Store pokemon can battle (sky mode)
	# Pokemon are allowed to participate even though they aren't flying or haven't levitate
	# Add new pokemon: ':NAME'
	CanBattle = [
		# Example: :BULBASAUR
		# Add below this: 
		:RATTATA, :EKANS, :MANKEY
	]

  def self.checkPkmnSky?(pkmn)
    list = []
    SkyPokemon.each { |species| list <<  GameData::Species.get(species).id }
		return list.include?(pkmn.species)
  end
  
	def self.checkExceptPkmn?(pkmn)
    list = []
    CanBattle.each { |species| list <<  GameData::Species.get(species).id }
		return list.include?(pkmn.species)
  end

  # Check pokemon in sky battle
	def self.canSkyBattle?(pkmn)
		return false if pkmn.egg? || pkmn.fainted?
    checktype    = pkmn.hasType?(:FLYING)
    checkability = pkmn.hasAbility?(:LEVITATE)
    checkpkmn    = SkyBattle.checkPkmnSky?(pkmn)
    except       = SkyBattle.checkExceptPkmn?(pkmn)
    return ((checktype || checkability) && !checkpkmn) || except
  end
  
  # Store move pokemon can't use (sky mode)
  # Add new move: ':MOVE'
  SkyMove = [
		:BODYSLAM, :BULLDOZE, :DIG, :DIVE, :EARTHPOWER, :EARTHQUAKE, :ELECTRICTERRAIN,
		:FISSURE, :FIREPLEDGE, :FLYINGPRESS, :FRENZYPLANT, :GEOMANCY, :GRASSKNOT,
		:GRASSPLEDGE, :GRASSYTERRAIN, :GRAVITY, :HEATCRASH, :HEAVYSLAM, :INGRAIN, 
		:LANDSWRATH, :MAGNITUDE, :MATBLOCK, :MISTYTERRAIN, :MUDSPORT, :MUDDYWATER,
		:ROTOTILLER, :SEISMICTOSS, :SLAM, :SMACKDOWN, :SPIKES, :STOMP, :SUBSTITUTE,
		:SURF, :TOXICSPIKES, :WATERPLEDGE, :WATERSPORT
  ]
  
  def self.checkMoveSky?(id)
    list = []
    SkyMove.each { |moves| list << GameData::Move.get(moves).id }
		return list.include?(id)
  end

	def self.skip_battle(outcome_variable)
    $game_temp.clear_battle_rules
    if $game_temp.memorized_bgm && $game_system.is_a?(Game_System)
      $game_system.bgm_pause
      $game_system.bgm_position = $game_temp.memorized_bgm_position
      $game_system.bgm_resume($game_temp.memorized_bgm)
    end
    $game_temp.memorized_bgm            = nil
    $game_temp.memorized_bgm_position   = 0
    $PokemonGlobal.nextBattleBGM        = nil
    $PokemonGlobal.nextBattleVictoryBGM = nil
    $PokemonGlobal.nextBattleCaptureME  = nil
    $PokemonGlobal.nextBattleBack       = nil
    $PokemonEncounters.reset_step_count
    outcome = 0 # Undecided
    pbSet(outcome_variable, outcome)
    return outcome
	end
end
#-------------------------------------------------------------------------------
# Set rules
#-------------------------------------------------------------------------------
class Game_Temp
  alias sky_inverse_battle_rule add_battle_rule
  def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "skybattle";     rules["skyBattle"] = true
    when "inversebattle"; rules["inverseBattle"] = true
    else; sky_inverse_battle_rule(rule, var)
    end
  end
end
#-------------------------------------------------------------------------------
# Set type for 'inverse'
#-------------------------------------------------------------------------------
module GameData
	class Type
		alias inverse_effect effectiveness
		def effectiveness(other_type)
			return Effectiveness::NORMAL_EFFECTIVE_ONE if !other_type
			ret = inverse_effect(other_type)
			if $inverse
				case ret
				when 0, 1; ret = 4
				when 4;    ret = 1
				end
			end
			return ret
		end
	end
end
#-------------------------------------------------------------------------------
# New Event -> :on_start_battle_inverse_sky_battle
#-------------------------------------------------------------------------------
# Set rule 'inverse'
$inverse = false
EventHandlers.add(:on_start_battle_inverse_sky_battle, :inverse_battle,
  proc {
		$inverse = true if $game_temp.battle_rules["inverseBattle"]
  }
)
EventHandlers.add(:on_end_battle, :inverse_battle,
  proc { |_decision, _canLose|
		$inverse = false
  }
)
#-------------------------------------------------------------------------------
# Set rule 'sky battle'
$sky_battle = false
class Battle
  alias sky_choose_move pbCanChooseMove?
	def pbCanChooseMove?(idxBattler, idxMove, showMessages, sleepTalk = false)
    ret = sky_choose_move(idxBattler, idxMove, showMessages, sleepTalk)
    battler = @battlers[idxBattler]
    move = battler.moves[idxMove]
    # Check move
    if ret && $sky_battle && SkyBattle.checkMoveSky?(move.id)
      pbDisplayPaused(_INTL("{1} can't use in a sky battle!",move.name)) if showMessages
      return false
    end
    return ret
  end
end
EventHandlers.add(:on_start_battle_inverse_sky_battle, :sky_battle,
  proc {
		$sky_battle = true if $game_temp.battle_rules["skyBattle"]
  }
)
# Set when finish battle
EventHandlers.add(:on_end_battle, :sky_battle,
  proc { |_, _|
		$sky_battle = false if $sky_battle
  }
)
#-------------------------------------------------------------------------------
# Recreate party - just sky battle (check pokemon)
#-------------------------------------------------------------------------------
# Create player's party
module BattleCreationHelperMethods
	module_function

	class << self
		alias sky_battle_set_up_player_trainers set_up_player_trainers
	end
	
	def set_up_player_trainers(foe_party)
		ret = sky_battle_set_up_player_trainers(foe_party)
		# Sky battle
		if $sky_battle
			sky_party = []
			ret[2].each { |p|
				sky_party << p if p && SkyBattle.canSkyBattle?(p)
			}
			ret[2] = sky_party
		end
		return ret
	end
end
#-------------------------------------------------------------------------------
# Set wild battle
#-------------------------------------------------------------------------------
class WildBattle
	class << self
		alias sky_battle_start_core start_core
		alias sky_battle_generate_foes generate_foes
	end

	def self.start_core(*args)
		# Sky battle
		outcome_variable = $game_temp.battle_rules["outcomeVar"] || 1
		EventHandlers.trigger(:on_start_battle_inverse_sky_battle)
		# Sky battle
		if $sky_battle
			# Foe
			foe_party = WildBattle.generate_foes(*args)
			if foe_party.size <= 0
				pbMessage(_INTL("Foe party doesn't have enough pokemon..."))
				return SkyBattle.skip_battle(outcome_variable)
			end
			# Player
			player_party = BattleCreationHelperMethods.set_up_player_trainers(foe_party)[2]
			if player_party.size <= 0
				pbMessage(_INTL("Your party doesn't have enough pokemon..."))
				return SkyBattle.skip_battle(outcome_variable)
			end
		end

		# Rotation battle
		if $rotation
			if foe_party.size < 3
				pbMessage(_INTL("Foe party doesn't have enough pokemon..."))
				return SkyBattle.skip_battle(outcome_variable)
			end
			# Player
			player_party = BattleCreationHelperMethods.set_up_player_trainers(foe_party)[2]
			if player_party.size < 3
				pbMessage(_INTL("Your party doesn't have enough pokemon..."))
				return SkyBattle.skip_battle(outcome_variable)
			end
		end

		return sky_battle_start_core(*args)
	end

	def self.generate_foes(*args)
		ret = sky_battle_generate_foes(*args)
		# Sky battle
		if $sky_battle
			sky_party = []
			ret.each { |p|
				sky_party << p if p && SkyBattle.canSkyBattle?(p)
			}
			ret = sky_party
		end
		return ret
	end
end
#-------------------------------------------------------------------------------
# Set trainer battle
#-------------------------------------------------------------------------------
class TrainerBattle
	class << self
		alias sky_battle_start_core start_core
		alias sky_battle_generate_foes generate_foes
	end

	def self.start_core(*args)
		# Sky battle
		outcome_variable = $game_temp.battle_rules["outcomeVar"] || 1
		EventHandlers.trigger(:on_start_battle_inverse_sky_battle)
		if $sky_battle
			# Foe
			foe_party = TrainerBattle.generate_foes(*args)[2]
			if foe_party.size <= 0
				pbMessage(_INTL("Foe party doesn't have enough pokemon..."))
				return SkyBattle.skip_battle(outcome_variable)
			end
			# Player
			player_party = BattleCreationHelperMethods.set_up_player_trainers(foe_party)[2]
			if player_party.size <= 0
				pbMessage(_INTL("Your party doesn't have enough pokemon..."))
				return SkyBattle.skip_battle(outcome_variable)
			end
		end

		# Rotation battle
		if $rotation
			if foe_party.size < 3
				pbMessage(_INTL("Foe party doesn't have enough pokemon..."))
				return SkyBattle.skip_battle(outcome_variable)
			end
			# Player
			player_party = BattleCreationHelperMethods.set_up_player_trainers(foe_party)[2]
			if player_party.size < 3
				pbMessage(_INTL("Your party doesn't have enough pokemon..."))
				return SkyBattle.skip_battle(outcome_variable)
			end
		end

		return sky_battle_start_core(*args)
	end

	def self.generate_foes(*args)
		ret = sky_battle_generate_foes(*args)
		# Sky battle
		if $sky_battle
			sky_party = []
			ret[2].each { |p|
				sky_party << p if p && SkyBattle.canSkyBattle?(p)
			}
			ret[2] = sky_party
		end
		return ret
	end
end