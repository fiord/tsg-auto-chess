require 'date'
require 'open3'
require 'benchmark'

$UNIT_TYPES = ["KING", "ASSASSIN", "WARRIOR", "MAGE"]
$W = 15
$H = 15
$MAX_TURNS = 1000
$id_cnt = 0

class Unit
  def initialize(_team, _type=nil, _level=1)
    if (_type.nil? || !$UNIT_TYPES.include?(_type)) then
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
    if (team) then
      x = $W - x
      y = $H - y
    end
    return "#{@ID} #{@TYPE} #{@hp} #{@atk} #{x} #{y}"
  end
end

class Player
  def initialize(team)
    @level = 1
    @units = [Unit.new(team, "KING")]
    @field_num = 0
    @gold = 5
    @time_left = 180000
    @kill = 0
    @shop = Array.new(3, Unit.new(team))
  end
end

class Game 
  def initialize(command1, command2)
    # 盤面などの用意
    @commands = [command1, command2]
    @players = [Player.new(0), Plkayer.new(1)]
    @field = Array.new($h).map{Array.new($w, nil)}
  end

  def run()
    Open3.popen3(@commands[0]) do |stdin1, stdout1, stderr1, w1|
      Open3.popen3(@commands[1]) do |stdin2, stdout2, stderr2, w2|
        @names = [stdout1.gets.chomp, stdout2.gets.chomp]
        @inputs = []
        @outputs = []
        @stdins = [stdin1, stdin2]
        @stdouts = [stdout1, stdout2]
        @stderrs = [stderr1, stderr2]
        for turn in 0...$MAX_TURNS do
          # gold処理
          for i in 0..1 do
            @players[i].gold += 1 + (@players[i].gold/10.0).floor + @players[i].kill
          end

          # input&output
          @output = [nil, nil]
          for i in 0..1 do
            bench = Benchmark.realtime do
              # input
              @stdins[i].puts turn
              @stdins[i].puts @players[i].time_left
              @stdins[i].puts @players[i].level + " " + @players[i ^ 1].level
              @stdins[i].puts @players[i].gold + " " + @players[i ^ 1].gold
              for j in 0...3 do
                @stdins[i].puts @players[i].shop[j].shopStr
              end
              @stdins[i].puts @players[i].units.length
              for j in 0...@players[i].units.length do
                @stdins[i].puts @players[i].units[j].print(i)
              end
              @stdins[i].puts @players[i ^ 1].units.length
              for j in 0...@players[i ^ 1].length do
                @stdins[i].puts @players[i].units[j].print(i)
              end
              #output
              command = @stdouts[i].gets
              n = @stdouts[i].gets
              dat = Array.new(n, nil)
              for j in 0...n do
                id, x, y = @stdouts[i].gets.chomp.split(" ").map(&:to_i)
                if (i)
                  x = $W - x
                  y = $H - y
                end
                dat[i] = {"id"=>id, "x"=>x, "y"=>y, "team"=>i}
              end
              @output[i] = {"command"=>command, "dat"=>dat}
            end
            @players[i].time_left -= bench * 1000
            @outputs.push(@output)

            # commandの処理
            for i in 0..1 do
              list = @output[i]["command"].chomp.split(" ")
              if (list.length == 0)
                 next
              end
              if (list[0] == "reset" && list.length <= 4)
                if (@players[i].gold >= 2)
                  @players[i].gold -= 2
                  for j in 1..3 do
                    if (list.length > j)
                      @players[i].shop[j-1] = Unit.new(i, list[j], @players[i].level)
                    else
                      @players[i].shop[j-1] = Unit.new(i, nil, @players[i].level)
                    end
                  end
                end
              elsif (list[0] == "buy" && list.length == 2)
                id = list[1].to_i
                for j in 0...3 do
                  if (id == @players[i].shop[j].ID && @players[i].gold >= @players[i].shop[j].value)
                    @players[i].gold -= @players[i].shop[j].value
                    @players[i].units.push(@players[i].shop[j])
                    @players[i].shop[j] = Unit.new(i, nil, @players[i].level)
                    break
                  end
                end
              elsif (list[0] == "move" && list.length == 4)
                id = list[1].to_i
                y = list[2].to_i
                x = list[3].to_i
                if (i)
                  x = $W - x
                  y = $H - y
                end
                unit = nil
                for j in 0...@players[i].units.length do
                  if (id == @players[i].units[j].ID)
                    unit = @players[i].units[j]
                    break
                  end
                end
                if (!unit.nil?)
                  if (0<=x&&x<$W&&0<=y&&y<$H&&@field[y][x].nil?)
                    if (unit.x==-1&&unit.y===1 && @players[i].field_num < 2 + @players[i].level)
                      unit.x = x
                      unit.y = y
                      @field[y][x] = unit
                      @players[i].field_num += 1
                    end
                  elsif (x==-1&&y==-1&&unit.x>=0)
                    @field[unit.y][unit.x] = nil
                    unit.x = -1
                    unit.y = -1
                    @players[i].field_num -= 1
                  end
                end
              elsif (list[0] == evolve && list.length == 4)
                materials = []
                ids = list[1..3].map(&:to_i)
                for j in 0...@players[i].units.length do
                  if (ids.include?(@players[i].units[j].ID))
                    materials.push(j)
                  end
                end
                if (materials.length == 3)
                  ok = true
                  for j in 0...3 do
                    if (@players[i].units[materials[j]].TYPE!=@players[i].units[materials[0]].TYPE)
                      ok = false
                      break
                    elsif (@players[i].units[materials[j]].x != -1 || @players[i].units[materials[j]].y != -1)
                      ok = false
                      break
                    end
                  end
                  if (ok)
                    new_unit = Unit.new(i, @players[i].units[materials[0]].TYPE)
                    sum_dat = [0, 0]
                    for j in 0...3 do
                      sum_dat[0] += @players[i].units[materials[j]].hp
                      sum_dat[1] += @players[i].units[materials[j]].atk
                    end
                    new_unit.hp = (sum_dat[0] * 2 / 3.0).round
                    new_unit.atk = (sum_dat[1] * 2 / 3.0).round
                    for j in 0...3 do
                      @players[i].units.delete_at(materials[j])
                    end
                    @players[i].units.push(new_unit)
                  end
                end
              elsif (list == ["levelup"])
                if (@players[i].gold >= 4)
                  @players[i].gold -= 4
                  @players[i].level += 1
              end
            end

            # moveの処理
            move_dat = output[0].dat + output[1].dat
            move_dat.sort_by! {|a| a["id"]}
            for i in 0...move_dat.length do
              # ここ少し計算量が悪い
              for j in 0...@players[move_dat[i]["team"]].units.length do
                unit = @players[move_dat[i]["team"]].units[j]
                if (unit.ID == move_dat[i]["id"])
                  if (unit.x > 0)
                    dist = max([(unit.x - move_dat[i]["x"]).abs, (unit.y - move_dat[i]["y"]).abs])
                    if (dist == 1 && @field[move_dat[i]["y"]][move_dat[i]["x"]].nil?)
                      @field[unit.y][unit.x] = nil
                      unit.x = move_dat[i]["x"]
                      unit.y = move_dat[i]["y"]
                      @field[unit.y][unit.x] = nil
                      break
                    end
                  end
                end
              end
            end

            # attackの処理
            for i in 0...$H do
              for j in 0...$W do
                if @field[i][j].nil?
                  next
                end
                if ["KING", "MAGE"].include?(@field[i][j].TYPE)
                  for ty in i-3..i+3 do
                    for tx in j-3..j+3 do
                      if (@field[ty][tx].nil? || @field[ty][tx].TEAM == @field[i][j].TEAM)
                        next
                      end
                      if @field[i][j].TYPE == "MAGE"
                        if @field[ty][tx].TYPE == "WARRIOR"
                          @field[ty][tx].hp -= @field[i][j].atk * 2
                        elsif @field[ty][tx].TYPE == "ASSASSIN"
                          @field[ty][tx].hp -= (@field[i][j].atk / 2.0).ceil
                        else
                          @field[ty][tx].hp -= @field[i][j].atk
                      else
                        @field[ty][tx].hp -= @field[i][j].atk
                      end
                    end
                  end
                else
                  for ty in i-1..i+1 do
                    for tx in j-1..j+1 do
                      if (@field[ty][tx].nil? || @field[ty][tx].TEAM == @field[i][j].TEAM)
                        next
                      end
                      if @field[i][j].TYPE == "ASSASSIN"
                        if @field[ty][tx].TYPE == "MAGE"
                          @field[ty][tx].hp -= @field[i][j].atk * 2
                        elsif @field[ty][tx].TYPE == "WARRIOR"
                          @field[ty][tx].hp -= (@field[i][j].atk / 2.0).ceil
                        else
                          @field[ty][tx].hp -= @field[i][j].atk
                        end
                      else
                        if @field[ty][tx].TYPE == "ASSASSIN"
                          @field[ty][tx].hp -= @field[i][j].atk * 2
                        elsif @field[ty][tx].TYPE == "MAGE"
                          @field[ty][tx].hp -= (@field[i][j].atk / 2.0).ceil
                        end
                      end
                    end
                  end
                end
              end
            end

            # dieの処理
            dead = [false, false]
            for i in 0..1 do
              @players[i^1].kill = 0
              for j in 0...@players[i].units[j].length do
                if @players[i].units[j].hp <= 0
                  if @players[i].units[j].TYPE == "KING"
                    dead[i] = true
                  end
                  @players[i].units.delete_at(j)
                  j -= 1
                  @players[i^1].kill += 1
                end
              end
            end

            # finish判定(TODO)
          end
        end
      end
    end
  end
end

game = Game.new(ARGV[0], ARGV[1])
game.run()