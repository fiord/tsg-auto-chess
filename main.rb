$UNIT_TYPES = ["KING", "ASSASSIN", "WARRIOR", "MAGE"]
$W = 15
$H = 15
$MAX_TURNS = 1000
$id_cnt = 0

class Unit
  def initialize(_type=nil, _team, _level=1)
    if (_type.nil?) then
      _type = $UNIT_TYPES[1...$UNIT_TYPES.length].sample
    end
    @TYPE = _type
    @TEAM = _team
    @ID = $id_cnt
    $id_cnt += 1
    @x = -1
    @y = -1

    if (@type == "KING") then
      @hp = 100
      @atk = 20
      @x = ($W - 1) / 2
      @y = (@TEAM == 1 ? 0 : $H - 1)
    elsif (@type == "ASSASSIN") then
      rand_result = rand(-1.0..1.0)
      rand_sum = rand_result
      @hp = 17 + 3 * _level + (5 * rand_result).round
      rand_result = rand(-1.0..1.0)
      rand_sum += rand_result
      @atk = 17 + 3 * _leev  + (5 * rand_result).round
      @value = (rand_sum + 3.0).round
    elsif (@type == "WARRIOR") then
      rand_result = rand(-1.0..1.0)
      rand_sum = rand_result
      @hp = 43 + 7 * _level + (10 * rand_result).round
      rand_result = rand(-1.0..1.0)
      rand_sum += rand_result
      @atk = 9 + _level + (3 * rand_result).round
      @value = (rand_sum + 3.0).round
    elsif (@type == "MAGE") then
      rand_result = rand(-1.0..1.0)
      rand_sum = rand_result
      @hp = 12 + 3 * _level + (5 * rand_result).round
      rand_result = rand(-1.0, 1.0)
      rand_sum += rand_result
      @atk = 3 + 2 * _level + (3 * rand_result)
      @value = (rand_sum + 3.0).round
    end
  end

  def shopStr
    return "#{@ID} #{@TYPE} #{@hp} #{@atk}"
  end

  def print(team)
    y = @y
    x = @x
    if (team == 2) then
      x = $W - x
      y = $H - y
    end
    return "#{@ID} #{@TYPE} #{@hp} #{@atk} #{x} #{y}"
  end
end
