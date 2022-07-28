#===============================================================================
# Smash Event
#===============================================================================
#Overwrites Essentials Stuff
def pbSmashEvent(event)
  return if !event
  if event.name[/cuttree/i]
    pbSEPlay("Cut", 80)
  elsif event.name[/smashrock/i]
    pbSEPlay("Rock Smash", 80)
  elsif event.name[/smashice/i]
    pbSEPlay("Ice Smash", 80)
  end
  pbMoveRoute(event,[
    PBMoveRoute::Wait, 2,
    PBMoveRoute::TurnLeft,
    PBMoveRoute::Wait, 2,
    PBMoveRoute::TurnRight,
    PBMoveRoute::Wait, 2,
    PBMoveRoute::TurnUp,
    PBMoveRoute::Wait, 2])
    pbWait(Graphics.frame_rate * 5 / 10)  # Fixed so Strength Event can be push over Smash Event
    event.erase
    $PokemonMap&.addErasedEvent(event.id)
end
