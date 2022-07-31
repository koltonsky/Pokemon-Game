#===============================================================================
# ** Better AI
# ** By #Not Important
#===============================================================================
=begin
Changes:
  - There is now an AI class for over 200 skill, beast mode.
	- Mega Evolution will only be used if:
    ~ One of the AI's moves is super effective
    ~ The opponent is on low HP (1/3)
  - The switching out for AI is now *much* more sophisticated, here are a few
    things I did:
    ~ If the user has a priority move, stay in
    ~ If the user is faster than the opponent and has a super effective move,
      stay in
		~ If the opponent is in the middle of a two-turn move, and cannot attack,
      stay in.
    ~ If the user is in the last turn of perish song, switch
    ~ I did more stuff but cannot be bothered to document it all here
  - Moves are NOT chosen as a possibility if they are not:
		~ Priority
		~ Super effective
    ~ Powerful
  - If no moves fit the above conditions, choose a random one
=end
MEGAEVOMETHOD = 1 #if its 1, it will start as false and run checks to make sure it needs to, if 2, the opposite
SPIRIT_POWERS = false
#-------------------------------------------------------------------------------
# AI skill levels:
#     0:     Wild Pokémon
#     1-31:  Basic trainer (young/inexperienced)
#     32-47: Some skill
#     48-99: High skill
#     100+:  Best trainers (Gym Leaders, Elite Four, Champion)
# NOTE: A trainer's skill value can range from 0-255, but by default only four
#       distinct skill levels exist. The skill value is typically the same as
#       the trainer's base money value.
module PBTrainerAI
	# Minimum skill level to be in each AI category.
	def self.minimumSkill; return 1;   end
	def self.mediumSkill;  return 32;  end
	def self.highSkill;    return 48;  end
	def self.bestSkill;    return 100; end
	def self.beastMode;    return 200; end
end
$nextMove   = nil
$nextTarget = nil
$nextQue    = 0
def superEffective?(battler1,battler2)
	types = [battler2.type1,battler2.type2]
	mod = 0
	battler1.moves do |m|
		types do |t|
			if PurifyChamberSet.isSuperEffective(m,t)
				mod += 1
			else
				mod -= 1
			end
		end
	end
	if mod >= 1
		return true
	end
	return false
end
def getSkill(battler,battle)
  begin
    s = @battle.pbGetOwnerFromBattlerIndex(battler).skill
    if !s
      s = 20
    end
    return s
  rescue
    return 20
  end
end
class PokeBattle_AI
	def initialize(battle)
		@battle = battle
	end
	
	def pbAIRandom(x); return rand(x); end
	
	def pbStdDev(choices)
		sum = 0
		n   = 0
		choices.each do |c|
			sum += c[1]
			n   += 1
		end
		return 0 if n<2
		mean = sum.to_f/n.to_f
		varianceTimesN = 0
		choices.each do |c|
			next if c[1]<=0
			deviation = c[1].to_f-mean
			varianceTimesN += deviation*deviation
		end
		# Using population standard deviation 
		# [(n-1) makes it a sample std dev, would be 0 with only 1 sample]
		return Math.sqrt(varianceTimesN/n)
	end
	
	#=============================================================================
	# Decide whether the opponent should Mega Evolve their Pokémon
	#=============================================================================
	def pbEnemyShouldMegaEvolve?(idxBattler)
		battler = @battle.battlers[idxBattler]
		opposing = []
    for i in @battle.battlers
      if i != battler
        if i
          if not(i.fainted?)
            if i.opposes?
              opposing.push(i)
            end
          end
        end
      end
    end
		moves = battler.moves
		if MEGAEVOMETHOD==1
      should = false
    else
      should = true
    end
		move   = false
    skill  = getSkill(idxBattler,@battler)
    #if @battle.pbGetOwnerFromBattlerIndex(idxBattler).skill
    #  skill = @battle.pbGetOwnerFromBattlerIndex(idxBattler).skill
    #end
		battler.moves do |move|
			opposing do |o|
				baseDmg = pbMoveBaseDamage(move,battler,o,skill)
				if pbRoughDamage(move,battler,o,skill,baseDmg) >= o.hp
					move = false
					$nextTarget = o
					$nextMove = move
					$nextQue = 1 
				end
			end
		end
		for o in opposing
			if superEffective?(battler,o)
				move = true
			end 
		end
		for o in opposing
			if o.hp <= (o.totalhp/3).floor
				should = true
			end
		end
		if move
			should = true
		end
		if should && @battle.pbCanMegaEvolve?(idxBattler)
			PBDebug.log("[AI] #{battler.pbThis} (#{idxBattler}) will Mega Evolve")
			return true
		end
		return false
	end
	
	#=============================================================================
	# Choose an action
	#=============================================================================
	def pbDefaultChooseEnemyCommand(idxBattler)
		return if pbEnemyShouldUseItem?(idxBattler)
		return if pbEnemyShouldWithdraw?(idxBattler)
		return if @battle.pbAutoFightMenu(idxBattler)
		@battle.pbRegisterMegaEvolution(idxBattler) if pbEnemyShouldMegaEvolve?(idxBattler)
		if SPIRIT_POWERS
			@battle.pbRegisterSpiritPower(idxBattler) if pbEnemyShouldUseSpiritPower?(idxBattler)
		end
    if pbChooseMoves(idxBattler)=="switch"
      return
    end
    pbChooseMoves(idxBattler)
	end
end


#-------------------------------------------------------------------------------
# Switching pkmn
class PokeBattle_AI
	#=============================================================================
	# Decide whether the opponent should switch Pokémon
	#=============================================================================
	def pbEnemyShouldWithdraw?(idxBattler)
		return pbEnemyShouldWithdrawEx?(idxBattler,false)
	end
	
	def shouldSwitchHandler(idxBattler,battler,opps)
    battler = @battle.battlers[idxBattler]
		skill = getSkill(idxBattler,@battle)
    #@battle.pbGetOwnerFromBattlerIndex(idxBattler).skill rescue 0
		moves = battler.moves
		hp = battler.hp
		thp = battler.totalhp
#		opps = battler.eachOpposing
		move_pri = false
		move_super = false
		faster = false
		opp_move_pri = false
    higherhp = false
		battler.moves do |m|
			if m.priority>0
				move_pri = true
			end
			opps do |o|
				if PurifyChamberSet.isSuperEffective(m.type,o.type1)
					move_super = true
				end
				if o.type2
					if PurifyChamberSet.isSuperEffective(m.type,o.type2)
						move_super = true
					end
				end
				if battler.stats[PBStats::SPEED]>o.stats[PBStats::SPEED] && battler.status != PBStatuses::PARALYSIS
					faster = true
				end
				oppmoves = o.moves
				oppmoves do |om|
					if om.priority>0
						opp_move_pri = true
					end
				end
				if hp > o.hp
					higherhp = true
				else
					higherhp = false
				end
				if @battle.pbSideSize(battler.index+1)==1 && !(battler.pbDirectOpposing.fainted?) && skill>=PBTrainerAI.highSkill
					opp = battler.pbDirectOpposing
					if opp.effects[PBEffects::HyperBeam]>0 ||
						(opp.hasActiveAbility?(:TRUANT) && opp.effects[PBEffects::Truant])
						hyper = true
					end
				end
			end
		end
		if move_pri && !opp_move_pri
			return false
		end
		if skill >= PBTrainerAI.mediumSkill
			if move_super && faster
				return false
			end
		end
		if skill >= PBTrainerAI.highSkill
			if (higherhp && faster) || (higherhp && move_pri) || (higherhp && faster && move_super)
				return false
			end
		end
		if skill >= PBTrainerAI.bestSkill
			if battler.effects[PBEffects::PerishSong]==1
				return true
			end
			if hyper
				return false
			end
		end
		if skill >= PBTrainerAI.beastMode
			if battler.effects[PBEffects::Encore]>0
				idxEncoredMove = battler.pbEncoredMoveIndex
				if idxEncoredMove>=0
					scoreSum   = 0
					scoreCount = 0
					battler.eachOpposing do |b|
						scoreSum += pbGetMoveScore(battler.moves[idxEncoredMove],battler,b,skill)
						scoreCount += 1
					end
					if scoreCount>0 && scoreSum/scoreCount<=20
						return false
					end
				end
			end
			if battler.status==PBStatuses::POISON && battler.statusCount>0
				toxicHP = battler.totalhp/16
				nextToxicHP = toxicHP*(battler.effects[PBEffects::Toxic]+1)
				if battler.hp<=nextToxicHP && battler.hp>toxicHP*2
					return true
				end
			end
		end
		return false
	end
	
	def pbEnemyShouldWithdrawEx?(idxBattler,forceSwitch)
		return false if @battle.wildBattle?
		if forceSwitch
			shouldSwitch = forceSwitch
		end
		batonPass = -1
		moveType = -1
		skill = getSkill(idxBattler,@battle)
    #@battle.pbGetOwnerFromBattlerIndex(idxBattler).skill rescue 0
		battler = @battle.battlers[idxBattler]
    opps = []
    for i in @battle.battlers
      if i != battler
        if i
          if not(i.fainted?)
            if i.opposes?
              opps.push(i)
            end
          end
        end
      end
    end
		#I removed all this bc it's handled in the shouldSwitchHandler def
		shouldSwitch = shouldSwitchHandler(idxBattler,battler,opps)
		if shouldSwitch
			list = []
			@battle.pbParty(idxBattler).each_with_index do |pkmn,i|
				next if !@battle.pbCanSwitch?(idxBattler,i)
				# If perish count is 1, it may be worth it to switch
				# even with Spikes, since Perish Song's effect will end
				if battler.effects[PBEffects::PerishSong]!=1
					# Will contain effects that recommend against switching
					spikes = battler.pbOwnSide.effects[PBEffects::Spikes]
					# Don't switch to this if too little HP
					if spikes>0
						spikesDmg = [8,6,4][spikes-1]
						if pkmn.hp<=pkmn.totalhp/spikesDmg
							next if !pkmn.hasType?(:FLYING) && !pkmn.hasActiveAbility?(:LEVITATE)
						end
					end
				end
				# moveType is the type of the target's last used move
				if moveType>=0 && PBTypes.ineffective?(pbCalcTypeMod(moveType,battler,battler))
					weight = 65
					typeMod = pbCalcTypeModPokemon(pkmn,battler.pbDirectOpposing(true))
					if PBTypes.superEffective?(typeMod.to_f/PBTypeEffectivenesss::NORMAL_EFFECTIVE)
						# Greater weight if new Pokemon's type is effective against target
						weight = 85
					end
					list.unshift(i) if pbAIRandom(100)<weight   # Put this Pokemon first
				elsif moveType>=0 && PBTypes.resistant?(pbCalcTypeMod(moveType,battler,battler))
					weight = 40
					typeMod = pbCalcTypeModPokemon(pkmn,battler.pbDirectOpposing(true))
					if PBTypes.superEffective?(typeMod.to_f/PBTypeEffectivenesss::NORMAL_EFFECTIVE)
						# Greater weight if new Pokemon's type is effective against target
						weight = 60
					end
					list.unshift(i) if pbAIRandom(100)<weight   # Put this Pokemon first
				else
					list.push(i)   # put this Pokemon last
				end
			end
			if list.length>0
				if batonPass>=0 && @battle.pbRegisterMove(idxBattler,batonPass,false)
					PBDebug.log("[AI] #{battler.pbThis} (#{idxBattler}) will use Baton Pass to avoid Perish Song")
					return true
				end
				if @battle.pbRegisterSwitch(idxBattler,list[0])
					PBDebug.log("[AI] #{battler.pbThis} (#{idxBattler}) will switch with " +
						"#{@battle.pbParty(idxBattler)[list[0]].name}")
					return 
				end
			end
		end
		return false
	end
	
	#=============================================================================
	# Choose a replacement Pokémon
	#=============================================================================
	def pbDefaultChooseNewEnemy(idxBattler,party)
		enemies = []
		party.each_with_index do |p,i|
			enemies.push(i) if @battle.pbCanSwitchLax?(idxBattler,i)
		end
		return -1 if enemies.length==0
		return pbChooseBestNewEnemy(idxBattler,party,enemies)
	end
	
	def pbChooseBestNewEnemy(idxBattler,party,enemies)
		return -1 if !enemies || enemies.length==0
		best    = -1
		bestSum = 0
		movesData = pbLoadMovesData
		enemies.each do |i|
			pkmn = party[i]
			sum  = 0
			pkmn.moves.each do |m|
				next if m.id==0
				moveData = movesData[m.id]
				next if moveData[MOVE_BASE_DAMAGE]==0
				@battle.battlers[idxBattler].eachOpposing do |b|
					bTypes = b.pbTypes(true)
					sum += PBTypes.getCombinedEffectiveness(moveData[MOVE_TYPE],
						bTypes[0],bTypes[1],bTypes[2])
				end
			end
			if best==-1 || sum>bestSum
				best = i
				bestSum = sum
			end
		end
		return best
	end
end
#===============================================================================
# * Attacks
class PokeBattle_AI
	#=============================================================================
	# Main move-choosing method
	#=============================================================================
	def pbChooseMoves(idxBattler)
		user        = @battle.battlers[idxBattler]
		wildBattler = (@battle.wildBattle? && @battle.opposes?(idxBattler))
		skill       = 0
		if !wildBattler
			skill     = getSkill(user.index,@battle)
      #@battle.pbGetOwnerFromBattlerIndex(user.index).skill || 0
		end
		# Get scores and targets for each move
		# NOTE: A move is only added to the choices array if it has a non-zero
		#       score.
		choices     = []
		user.eachMoveWithIndex do |m,i|
			next if !@battle.pbCanChooseMove?(idxBattler,i,false)
			if wildBattler
				pbRegisterMoveWild(user,i,choices)
			else
				pbRegisterMoveTrainer(user,i,choices,skill)
			end
		end
		# Figure out useful information about the choices
		totalScore = 0
		maxScore   = 0
		choices.each do |c|
			totalScore += c[1]
			maxScore = c[1] if maxScore<c[1]
		end
		# Log the available choices
		if $INTERNAL
			logMsg = "[AI] Move choices for #{user.pbThis(true)} (#{user.index}): "
			choices.each_with_index do |c,i|
				logMsg += "#{user.moves[c[0]].name}=#{c[1]}"
				logMsg += " (target #{c[2]})" if c[2]>=0
				logMsg += ", " if i<choices.length-1
			end
			PBDebug.log(logMsg)
		end
		# Find any preferred moves and just choose from them
		if !wildBattler && skill>=PBTrainerAI.highSkill && maxScore>100
			stDev = pbStdDev(choices)
			if stDev>=40
				preferredMoves = []
				choices.each do |c|
					next if c[1]<200 && c[1]<maxScore*0.8
					if c.priority != 0
						preferredMoves.push(c)
						preferredMoves.push(c) if user.hp <= (user.totalhp/3).floor
					end
					user.eachOpposing do |o|
						superEffective = superEffective?(c,o)
						if superEffective
							prefferedMoves.push(c)
						end
					end
					# preferredMoves.push(c) No. Bad moves should not be added to possible moves
					preferredMoves.push(c) if c[1]==maxScore   # Doubly prefer the best move
				end
				if preferredMoves.length == 0
					choices.each do |move|
						prefferedMoves.push(move) #choose rand move bc all bad
					end
				end
        opposing = []
        for i in @battle.battlers
          if i != battler
            if i
              if not(i.fainted?)
                if i.opposes?
                  opposing.push(i)
                end
              end
            end
          end
        end
        for move in prefferedMoves
          for opp in opposing
            if ((opp.type1 == move.type) or (opp.type2 == move.type))
              prefferedMoves.delete(move) 
            end
          end
        end
				if preferredMoves.length>0
					m = preferredMoves[pbAIRandom(preferredMoves.length)]
					PBDebug.log("[AI] #{user.pbThis} (#{user.index}) prefers #{user.moves[m[0]].name}")
					@battle.pbRegisterMove(idxBattler,m[0],false)
					@battle.pbRegisterTarget(idxBattler,m[2]) if m[2]>=0
					return
				end
			end
		end
		# Decide whether all choices are bad, and if so, try switching instead
		if !wildBattler && skill>=PBTrainerAI.highSkill
			badMoves = false
			if (maxScore<=20 && user.turnCount>2) ||
				(maxScore<=40 && user.turnCount>5)
				badMoves = true if pbAIRandom(100)<80
			end
			if !badMoves && totalScore<100 && user.turnCount>1
				badMoves = true
				choices.each do |c|
					next if !user.moves[c[0]].damagingMove?
					badMoves = false
					break
				end
				badMoves = false if badMoves
			end
			if badMoves && pbEnemyShouldWithdrawEx?(idxBattler,true)
				if $INTERNAL
					PBDebug.log("[AI] #{user.pbThis} (#{user.index}) will switch due to terrible moves lol. you should have better moves tbh")
				end
				return "switch"
			end
		end
		battler = @battle.battlers[idxBattler]
		moves = battler.moves
		skill = getSkill(idxBattler,@battle)
    #@battle.pbGetOwnerFromBattlerIndex(idxBattler) rescue 0
		battler.moves do |move|
			for o in opposing
				baseDmg = pbMoveBaseDamage(move,battler,o,skill)
				if pbRoughDamage(move,battler,o,skill,baseDmg) >= o.hp
					$nextTarget = o
					$nextMove = move
					$nextQue = 1 
				end
			end
		end
		# Randomly choose a move to use
		if choices.length==0
			# If there are no calculated choices, use Struggle (or an Encored move)
			@battle.pbAutoChooseMove(idxBattler)
		else
			# Randomly choose a move from the choices and register it
			if !($nextQue == 1)
				randNum = pbAIRandom(totalScore)
				choices.each do |c|
					randNum -= c[1]
					next if randNum>=0
					@battle.pbRegisterMove(idxBattler,c[0],false)
					@battle.pbRegisterTarget(idxBattler,c[2]) if c[2]>=0
					break
				end
			else
				@battle.pbRegisterMove(idxBattler,$nextMove,false)
				@battle.pbRegisterTarget(idxBattler,$nextTarget) if $nextTarget>=0
				$nextQue = 0
			end
		end
		# Log the result
		if @battle.choices[idxBattler][2]
			PBDebug.log("[AI] #{user.pbThis} (#{user.index}) will use #{@battle.choices[user.index][2].name} boom boom you die")
		end
  end
	
	#=============================================================================
	# Get scores for the given move against each possible target
	#=============================================================================
	# Wild Pokémon choose their moves randomly.
	# If you dont want this and want wild battles to be hard tell me		
	def pbRegisterMoveWild(user,idxMove,choices)
		choices.push([idxMove,100,-1])   # Move index, score, target
	end
	
	# Trainer Pokémon calculate how much they want to use each of their moves.
	def pbRegisterMoveTrainer(user,idxMove,choices,skill)
		move = user.moves[idxMove]
		targetType = move.pbTarget(user)
		if PBTargets.multipleTargets?(targetType)
			# If move affects multiple battlers and you don't choose a particular one
			totalScore = 0
			@battle.eachBattler do |b|
				next if !@battle.pbMoveCanTarget?(user.index,b.index,targetType)
				score = pbGetMoveScore(move,user,b,skill)
				totalScore += ((user.opposes?(b)) ? score : -score)
			end
			choices.push([idxMove,totalScore,-1]) if totalScore>0
		elsif PBTargets.noTargets?(targetType)
			# If move has no targets, affects the user, a side or the whole field
			score = pbGetMoveScore(move,user,user,skill)
			choices.push([idxMove,score,-1]) if score>0
		else
			# If move affects one battler and you have to choose which one
			scoresAndTargets = []
			@battle.eachBattler do |b|
				next if !@battle.pbMoveCanTarget?(user.index,b.index,targetType)
				next if PBTargets.canChooseFoeTarget?(targetType) && !user.opposes?(b)
				score = pbGetMoveScore(move,user,b,skill)
				scoresAndTargets.push([score,b.index]) if score>0
			end
			if scoresAndTargets.length>0
				# Get the one best target for the move
				scoresAndTargets.sort! { |a,b| b[0]<=>a[0] }
				choices.push([idxMove,scoresAndTargets[0][0],scoresAndTargets[0][1]])
			end
		end
	end
	
	#=============================================================================
	# Get a score for the given move being used against the given target
	#=============================================================================
	def pbGetMoveScore(move,user,target,skill=100)
		skill = PBTrainerAI.minimumSkill if skill<PBTrainerAI.minimumSkill
		score = 100
		score = pbGetMoveScoreFunctionCode(score,move,user,target,skill)
		# A score of 0 here means it absolutely should not be used
		return 0 if score<=0
		if skill>=PBTrainerAI.mediumSkill
			# Prefer damaging moves if AI has no more Pokémon or AI is less clever
			if @battle.pbAbleNonActiveCount(user.idxOwnSide)==0
				if !(skill>=PBTrainerAI.highSkill && @battle.pbAbleNonActiveCount(target.idxOwnSide)>0)
					if move.statusMove?
						score /= 1.5
					elsif target.hp<=target.totalhp/2
						score *= 1.5
					end
				end
			end
			# Don't prefer attacking the target if they'd be semi-invulnerable
			if skill>=PBTrainerAI.highSkill && move.accuracy>0 &&
				(target.semiInvulnerable? || target.effects[PBEffects::SkyDrop]>=0)
				miss = true
				miss = false if user.hasActiveAbility?(:NOGUARD) || target.hasActiveAbility?(:NOGUARD)
				if miss && pbRoughStat(user,PBStats::SPEED,skill)>pbRoughStat(target,PBStats::SPEED,skill)
					# Knows what can get past semi-invulnerability
					if target.effects[PBEffects::SkyDrop]>=0
						miss = false if move.hitsFlyingTargets?
					else
						if target.inTwoTurnAttack?("0C9","0CC","0CE")   # Fly, Bounce, Sky Drop
							miss = false if move.hitsFlyingTargets?
						elsif target.inTwoTurnAttack?("0CA")          # Dig
							miss = false if move.hitsDiggingTargets?
						elsif target.inTwoTurnAttack?("0CB")          # Dive
							miss = false if move.hitsDivingTargets?
						end
					end
				end
				score -= 80 if miss
			end
			# Pick a good move for the Choice items
			if user.hasActiveItem?([:CHOICEBAND,:CHOICESPECS,:CHOICESCARF])
				if move.baseDamage>=60;     score += 60
				elsif move.damagingMove?;   score += 30
				elsif move.function=="0F2"; score += 70   # Trick
				else;                       score -= 60
				end
			end
			# If user is asleep, prefer moves that are usable while asleep
			if user.status==PBStatuses::SLEEP && !move.usableWhenAsleep?
				hasSleepMove = false
				user.eachMove do |m|
					next unless m.usableWhenAsleep?
					score -= 60
					break
				end
			end
			# If user is frozen, prefer a move that can thaw the user
			if user.status==PBStatuses::FROZEN
				if move.thawsUser?
					score += 40
				else
					user.eachMove do |m|
						next unless m.thawsUser?
						score -= 60
						break
					end
				end
			end
			# If target is frozen, don't prefer moves that could thaw them
			if target.status==PBStatuses::FROZEN
				user.eachMove do |m|
					next if m.thawsUser?
					score -= 60
					break
				end
			end
		end
		# Adjust score based on how much damage it can deal
		if move.damagingMove?
			score = pbGetMoveScoreDamage(score,move,user,target,skill)
		else   # Status moves
			# Don't prefer attacks which don't deal damage
			score -= 10
			# Account for accuracy of move
			accuracy = pbRoughAccuracy(move,user,target,skill)
			score *= accuracy/100.0
			score = 0 if score<=10 && skill>=PBTrainerAI.highSkill
		end
		score = score.to_i
		score = 0 if score<0
		return score
	end
	
	#=============================================================================
	# Add to a move's score based on how much damage it will deal (as a percentage
	# of the target's current HP)
	#=============================================================================
	def pbGetMoveScoreDamage(score,move,user,target,skill)
		# Don't prefer moves that are ineffective because of abilities or effects
		return 0 if score<=0 || pbCheckMoveImmunity(score,move,user,target,skill)
		# Calculate how much damage the move will do (roughly)
		baseDmg = pbMoveBaseDamage(move,user,target,skill)
		realDamage = pbRoughDamage(move,user,target,skill,baseDmg)
		# Account for accuracy of move
		accuracy = pbRoughAccuracy(move,user,target,skill)
		realDamage *= accuracy/100.0
		# Two-turn attacks waste 2 turns to deal one lot of damage
		if move.chargingTurnMove? || move.function=="0C2"   # Hyper Beam
			realDamage *= 2/3   # Not halved because semi-invulnerable during use or hits first turn
		end
		# Prefer flinching external effects (note that move effects which cause
		# flinching are dealt with in the function code part of score calculation)
		if skill>=PBTrainerAI.mediumSkill
			if !target.hasActiveAbility?(:INNERFOCUS) &&
				!target.hasActiveAbility?(:SHIELDDUST) &&
				target.effects[PBEffects::Substitute]==0
				canFlinch = false
				if move.canKingsRock? && user.hasActiveItem?([:KINGSROCK,:RAZORFANG])
					canFlinch = true
				end
				if user.hasActiveAbility?(:STENCH) && !move.flinchingMove?
					canFlinch = true
				end
				realDamage *= 1.3 if canFlinch
			end
		end
		# Convert damage to percentage of target's remaining HP
		damagePercentage = realDamage*100.0/target.hp
		# Don't prefer weak attacks
		#    damagePercentage /= 2 if damagePercentage<20
		# Prefer damaging attack if level difference is significantly high
		damagePercentage *= 1.2 if user.level-10>target.level
		# Adjust score
		damagePercentage = 120 if damagePercentage>120   # Treat all lethal moves the same
		damagePercentage += 40 if damagePercentage>100   # Prefer moves likely to be lethal
		score += damagePercentage.to_i
		return score
	end
end
#------------------------------------------------------------------------------#
#                            Thanks for using!																 #
#------------------------------------------------------------------------------#	
PluginManager.register({                                                 
		:name    => "Better AI",                             
		:version => "2.0",                                   
		:link    => "https://www.pokecommunity.com/showthread.php?t=442787",             
		:credits => ["#Not Important"]
})