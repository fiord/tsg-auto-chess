require 'date'
require 'open3'
require 'json'
require 'benchmark'

$UNIT_TYPES = ["KING", "ASSASSIN", "WARRIOR", "MAGE"]
$W = 9
$H = 9
$MAX_TURNS = 1000
$id_cnt = 0

class Unit
  attr_reader :TYPE, :TEAM, :ID
  attr_accessor :x, :y, :hp, :atk, :value
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

    if (@TYPE == "KING")
      @hp = 100
      @atk = 20
      @x = ($W - 1) / 2
      @y = (@TEAM == 1 ? 0 : $H - 1)
    else
      @hp = 43 + 7 * _level
      @atk = 7 + 3 * _level
      @value = Random.rand(2..4)
    end
  end

  def shopStr
    return "#{@ID} #{@TYPE} #{@hp} #{@atk} #{@value}"
  end

  def print(team)
    y = @y
    x = @x
    if (team == 1 && x != -1) then
      x = $W - 1 - x
      y = $H - 1 - y
    end
    return "#{@ID} #{@TYPE} #{@hp} #{@atk} #{x} #{y}"
  end
end

class Player
  attr_accessor :level, :units, :field_num, :gold, :time_left, :kill, :shop
  def initialize(team)
    @level = 1
    @units = [Unit.new(team, "KING")]
    @field_num = 0
    @gold = 4
    @time_left = 180000
    @kill = 0
    @shop = Array.new(3, nil)
  end
end

class Game 
  def initialize(command1, command2)
    # 盤面などの用意
    @commands = [command1, command2]
    @players = [Player.new(0), Player.new(1)]
    for i in 0..1 do
      @players[i].shop = (0...3).to_a.map{|j|Unit.new(i,$UNIT_TYPES[j+1])}
    end
    @field = Array.new($H).map{Array.new($W, nil)}
    for i in 0..1 do
      @field[@players[i].units[0].y][@players[i].units[0].x] = @players[i].units[0]
    end
  end

  def run()
    @dump_data = []
    Open3.popen3(@commands[0]) do |stdin1, stdout1, stderr1, thread1|
      Open3.popen3(@commands[1]) do |stdin2, stdout2, stderr2, thread2|
        @names = [stdout1.gets.chomp, stdout2.gets.chomp]
        puts @names
        @inputs = []
        @outputs = []
        @stdins = [stdin1, stdin2]
        @stdouts = [stdout1, stdout2]
        @stderrs = [stderr1, stderr2]
        @threads = [thread1, thread2]
        for turn in 0...$MAX_TURNS do
          # gold処理
          for i in 0..1 do
            @players[i].gold += 1 + [5, (@players[i].gold / 10.0).floor].max + @players[i].kill
          end

          # dump
          @dump_data.push(Marshal.load(Marshal.dump(@players)))

          # input&output
          @output = [nil, nil]
          for i in 0..1 do
            bench = Benchmark.realtime do
              # input
              @stdins[i].puts turn
              @stdins[i].puts @players[i].time_left.to_i
              @stdins[i].puts "#{@players[i].level} #{@players[i ^ 1].level}"
              @stdins[i].puts "#{@players[i].gold} #{@players[i ^ 1].gold}"
              puts "#{@names[i]} in:#{turn}"
              puts "#{@names[i]} in:#{@players[i].time_left.to_i}"
              puts "#{@names[i]} in:#{@players[i].level} #{@players[i ^ 1].level}"
              puts "#{@names[i]} in:#{@players[i].gold} #{@players[i ^ 1].gold}"
              for j in 0...3 do
                @stdins[i].puts @players[i].shop[j].shopStr
                puts "#{@names[i]} in:#{@players[i].shop[j].shopStr}"
              end
              @stdins[i].puts @players[i].units.length
              puts "#{@names[i]} in:#{@players[i].units.length}"
              for j in 0...@players[i].units.length do
                @stdins[i].puts @players[i].units[j].print(i)
                puts "#{@names[i]} in:#{@players[i].units[j].print(i)}"
              end
              @stdins[i].puts @players[i ^ 1].units.length
              puts "#{@names[i]} in:#{@players[i ^ 1].units.length}"
              for j in 0...@players[i ^ 1].units.length do
                @stdins[i].puts @players[i ^ 1].units[j].print(i)
                puts "#{@names[i]} in:#{@players[i ^ 1].units[j].print(i)}"
              end
              #output
              command = @stdouts[i].gets.chomp
              puts "#{@names[i]} out:#{command}"
              n = @stdouts[i].gets.chomp.to_i
              puts "#{@names[i]} out:#{n}"
              dat = Array.new(n, nil)
              for j in 0...n do
                id, x, y = @stdouts[i].gets.chomp.split(" ").map(&:to_i)
                puts "#{@names[i]} out:#{id} #{x} #{y}"
                if (i == 1 && x != -1)
                  x = $W - 1 - x
                  y = $H - 1 - y
                end
                dat[j] = {"id"=>id, "x"=>x, "y"=>y, "team"=>i}
              end
              @output[i] = {"command"=>command, "dat"=>dat}
            end
            @players[i].time_left -= bench * 1000
            @outputs.push(@output)
          end

          # commandの処理
          ignore_list = []
          for i in 0..1 do
            list = @output[i]["command"].chomp.split(" ")
            if (list.length == 0)
                next
            elsif (list[0] == "buy" && list.length == 4)
              id = list[1].to_i
              to_x = list[2].to_i
              to_y = list[3].to_i
              if (to_x.between?(0, $W - 1) && to_y.between?(0, $H - 1) && [to_x - @players[i].units[0].x, to_y - @players[i].units[0].y].max <= 3)
                for j in 0...3 do
                  if (id == @players[i].shop[j].ID && @players[i].gold >= @players[i].shop[j].value)
                    @players[i].gold -= @players[i].shop[j].value
                    @players[i].shop[j].x = to_x
                    @players[i].shop[j].y = to_y
                    @players[i].units.push(@players[i].shop[j])
                    ignore_list.push(@players[i].shop[j])
                    @players[i].shop[j] = Unit.new(i, @players[i].shop[j].TYPE, @players[i].level)
                    break
                  end
                end
              end
            elsif (list[0] == "evolve" && list.length == 4)
              materials = []
              ids = list[1..3].map(&:to_i)
              for j in 0...3 do
                material = @players[i].units.find{|u| u.ID == ids[j]}
                if(material)
                  materials.push(material)
                end
              end
              if (materials.length == 3)
                ok = true
                for j in 0...3 do
                  if (materials[j].TYPE != materials[0].TYPE)
                    ok = false
                    break
                  end
                end
                if (ok)
                  materials[0].hp = (materials.map{|u| u.hp }.sum / 3.5 * 2).to_i
                  materials[0].atk = (materials.map{|u| u.atk }.sum / 3.5 * 2).to_i
                  @players[i].units.delete_if{|u| materials[1..2].include?(u)}
                end
              end
            elsif (list == ["levelup"])
              if (@players[i].gold >= 4)
                @players[i].gold -= 4
                @players[i].level += 1
              end
            end
          end

          # moveの処理
          # @field = Array.new($H).map{Array.new($W).fill(nil)}
          # for i in 0..1 do
          #   for j in 0...@players[i].units.length do
          #    if @players[i].units[j].x != -1
          #      @field[@players[i].units[j].y][@players[i].units[j].x] = @players[i].units[j]
          #    end
          #  end
          #end
          move_dat = @output[0]["dat"] + @output[1]["dat"]
          move_dat.sort_by! {|a| a["id"]}
          for i in 0...move_dat.length do
            if (move_dat[i]["x"]<0 || move_dat[i]["x"]>=$W || move_dat[i]["y"]<0 || move_dat[i]["y"]>=$H)
              next
            end
            # ここ少し計算量が悪い
            for j in 0...@players[move_dat[i]["team"]].units.length do
              unit = @players[move_dat[i]["team"]].units[j]
              if (unit.ID == move_dat[i]["id"])
                if (!ignore_list.include?(unit))
                  dist = [(unit.x - move_dat[i]["x"]).abs, (unit.y - move_dat[i]["y"]).abs].max
                  if (dist == 1 && @field[move_dat[i]["y"]][move_dat[i]["x"]].nil?)
                    @field[unit.y][unit.x] = nil
                    unit.x = move_dat[i]["x"]
                    unit.y = move_dat[i]["y"]
                    @field[unit.y][unit.x] = unit
                    break
                  end
                end
              end
            end
          end

          # attackの処理
          for i in 0...$H do
            for j in 0...$W do
              if @field[i][j].nil? || ignore_list.include?(@field[i][j])
                next
              end
              if (@field[i][j].TYPE == "KING")
                for ty in (i-3)..(i+3) do
                  if ty<0 || ty>=$H
                    next
                  end
                  for tx in (j-3)..(j+3) do
                    if tx<0 || tx>=$W
                      next
                    end
                    if (@field[ty][tx].nil? || @field[ty][tx].TEAM == @field[i][j].TEAM)
                      next
                    end
                    @field[ty][tx].hp -= @field[i][j].atk
                  end
                end
              else
                for ty in (i-1)..(i+1) do
                  for tx in (j-1)..(j+1) do
                    if ty < 0 || ty >= $H || tx < 0 || tx >= $W
                      next
                    end
                    if (@field[ty][tx].nil? || @field[ty][tx].TEAM == @field[i][j].TEAM)
                      next
                    end
                    if (@field[i][j].TYPE == "ASSASSIN")
                      if @field[ty][tx].TYPE == "MAGE"
                        @field[ty][tx].hp -= @field[i][j].atk * 2
                      elsif @field[ty][tx].TYPE == "WARRIOR"
                        @field[ty][tx].hp -= (@field[i][j].atk / 2.0).ceil
                      else
                        @field[ty][tx].hp -= @field[i][j].atk
                      end
                    elsif (@field[i][j].TYPE == "WARRIOR")
                      if @field[ty][tx].TYPE == "ASSASSIN"
                        @field[ty][tx].hp -= @field[i][j].atk * 2
                      elsif @field[ty][tx].TYPE == "MAGE"
                        @field[ty][tx].hp -= (@field[i][j].atk / 2.0).ceil
                      else
                        @field[ty][tx].hp -= @field[i][j].atk
                      end
                    else
                      if (@field[ty][tx].TYPE == "WARRIOR")
                        @field[ty][tx].hp -= @field[i][j].atk * 2
                      elsif (@field[ty][tx].TYPE == "ASSASSIN")
                        @field[ty][tx].hp -= (@field[i][j].atk / 2.0).ceil
                      else
                        @field[ty][tx].hp -= @field[i][j].atk
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
            (@players[i].units.length-1).downto(0){|j|
              if @players[i].units[j].hp <= 0
                if @players[i].units[j].TYPE == "KING"
                  dead[i] = true
                end
                @players[i].units.delete_at(j)
                @players[i^1].kill += 1
              end
            }
          end

          for i in 0..1 do
            if @players[i].time_left <= 0
              dead[i] = true
            end
          end
          if dead != [false, false]
            @result = dead
            for i in 0..1 do
              @stdins[i].close
              if @threads[i].alive?
                @threads[i].kill
              end
            end
            break
          end
        end
        if @result.nil?
          @result = [(@players[0].units[0].hp < @players[1].units[0].hp), (@players[1].units[0].hp < @players[0].units[0].hp)]
          for i in 0..1 do
            @stdins[i].close
            if @threads[i].alive?
              @threads[i].kill
            end
          end
        end
      end
    end
    @dump_data.push(Marshal.load(Marshal.dump(@players)))
    # logへ出力
    p @result
    filename = "visualizer/log/" + (DateTime.now).strftime("%Y%m%d%H%M%S")+"-#{@names[0]}-#{@names[1]}.log"
    open(filename, "w") do |file|
      file.puts "#{@names[0]} #{@names[1]}"
      file.puts "#{@result[0]} #{@result[1]}"
      for i in 0...@dump_data.length
        # turn
        file.puts i
        # time_lefts
        file.puts "#{@dump_data[i][0].time_left} #{@dump_data[i][1].time_left}"
        # levels
        file.puts "#{@dump_data[i][0].level} #{@dump_data[i][1].level}"
        # golds
        file.puts "#{@dump_data[i][0].gold} #{@dump_data[i][1].gold}"
        # shop
        for j in 0..1 do
          for k in 0...3 do
            file.puts @dump_data[i][j].shop[k].shopStr
          end
        end
        # units
        for j in 0..1 do
          file.puts @dump_data[i][j].units.length
          for k in 0...@dump_data[i][j].units.length do
            file.puts @dump_data[i][j].units[k].print(0)
          end
        end
      end
    end
    puts "log was dumped to #{filename}"
  end
end

game = Game.new(ARGV[0], ARGV[1])
game.run()
