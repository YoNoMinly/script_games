require 'ruby2d'

set title: "Mario in Ruby2D", width: 1000, height: 600
set background: 'skyblue'

# --- Параметри ---
level_length = 3000
spawn_x = 100
spawn_y = 100
platform_height = 40
coin_size = 30
gravity = 0.8
jump_power = -18
camera_speed = 3
player_size = 40

# --- Ігровий стан ---
camera_x = 0
camera_started = false
start_time = Time.now
velocity_y = 0
on_ground = false
score = 0
lives = 3
game_over = false

# --- Гравець ---
player_world_x = spawn_x
player_world_y = spawn_y
player = Square.new(x: spawn_x, y: spawn_y, size: player_size, color: 'red')

# --- Текст ---
score_text = Text.new("Coins: 0", x: 10, y: 10, size: 20, color: 'yellow')
lives_text = Text.new("Lives: #{lives}", x: 10, y: 40, size: 20, color: 'white')
game_over_text = Text.new("", x: 400, y: 200, size: 40, color: 'red')


def overlaps?(x, y, size, list)
  list.any? do |item|
    shape = item[:shape]
    sx = shape.x
    sy = shape.y

    # Отримаємо розміри (width, height)
    sw = shape.respond_to?(:width) ? shape.width : shape.size
    sh = shape.respond_to?(:height) ? shape.height : shape.size

    x < sx + sw && x + size > sx &&
    y < sy + sh && y + size > sy
end
end


# --- Генерація рівня ---
def generate_level(length, platform_height, coin_size)
  platforms, obstacles, enemies, coins = [], [], [], []

  x = 0
  while x < length
    width = rand(150..300)
    y = rand(400..560)
    platform = Rectangle.new(x: x, y: y, width: width, height: platform_height, color: 'green')
    platforms << { shape: platform, original_x: x }
    x += width + rand(50..200)
  end

  # Фініш
  goal_platform = platforms.last
  goal_x = goal_platform[:original_x] + goal_platform[:shape].width / 2
  goal = { shape: Rectangle.new(x: goal_x, y: goal_platform[:shape].y - 100, width: 20, height: 100, color: 'yellow'), original_x: goal_x }

  # Перешкоди
  platforms.each do |plat|
    s = plat[:shape]
    next if s.width < 100
    obs_x = rand(plat[:original_x] + 20..plat[:original_x] + s.width - 40)
    obs_y = s.y - 40
    obstacle = Rectangle.new(x: obs_x, y: obs_y, width: 20, height: 40, color: 'gray')
    obstacles << { shape: obstacle, original_x: obs_x }
  end
  # Колізія з перешкодами (блоки)


  # Монети
platforms.each do |plat|
  s = plat[:shape]
  num_coins = rand(1..2)
  tries = 0
  finish_line = plat[:original_x] + s.width # Фінішна лінія — правий край платформи

  num_coins.times do
    placed = false
    while !placed && tries < 100
      # Генеруємо випадкові координати для монетки, враховуючи межу фінішу
      x = rand(plat[:original_x] + 10..[finish_line - coin_size - 10, plat[:original_x] + s.width - coin_size - 10].min)
      y = s.y - coin_size

      # Перевірка на перетин з іншими монетами, ворогами або перешкодами
      unless overlaps?(x, y, coin_size, coins) || overlaps?(x, y, coin_size, enemies) || overlaps?(x, y, coin_size, obstacles)
        coin = Square.new(x: x, y: y, size: coin_size, color: 'yellow')
        coins << { shape: coin, original_x: x }
        placed = true
      end

      tries += 1
    end
  end
end



  # Вороги
platforms.each_with_index do |plat, i|
  next if i == 0 || i == platforms.size - 1
  s = plat[:shape]
  tries = 0
  placed = false

  while !placed && tries < 100
    enemy_x = plat[:original_x] + rand(20..(s.width - 40))
    enemy_y = s.y - 30

 unless overlaps?(enemy_x, enemy_y, 30, coins) ||
           overlaps?(enemy_x, enemy_y, 30, enemies) ||
           overlaps?(enemy_x, enemy_y, 30, obstacles)
      enemy = Square.new(x: enemy_x, y: enemy_y, size: 30, color: 'purple')
      enemies << { shape: enemy, original_x: enemy_x, direction: 1, platform: plat }
      placed = true
    end

    tries += 1
  end
end

  # Колізія ворогів з перешкодами
enemies.each do |enemy|
  obstacles.each do |obs|
    e = enemy[:shape]
    o = obs[:shape]

    if enemy[:original_x] + e.size > obs[:original_x] &&
       enemy[:original_x] < obs[:original_x] + o.width &&
       e.y + e.size > o.y &&
       e.y < o.y + o.height
      enemy[:direction] *= -1
    end
  end
end


  [platforms, obstacles, coins, enemies, goal]
end

platforms, obstacles, coins, enemies, goal = generate_level(level_length, platform_height, coin_size)
total_coins = coins.size
score_text.text = "Coins: #{score}/#{total_coins}"

# --- Ввід ---
keys = {}
on :key_held do |event| keys[event.key] = true end
on :key_up   do |event| keys[event.key] = false end
on :key_down do |event|
  if event.key == 'space' && on_ground && !game_over
    velocity_y = jump_power
    on_ground = false
  end
end

# --- Відновлення ---
def respawn
  global_camera = 0
  $camera_x = 0
  $player_world_x = spawn_x
  $player.y = spawn_y
  $velocity_y = 0
  $camera_started = false
  $start_time = Time.now+start_time
end

# --- Ігровий цикл --- 
update do
  next if game_over

  # Старт камери
  camera_started = true if Time.now - start_time > 3
  camera_x += camera_speed if camera_started

  # Рух
  player_world_x -= 5 if keys['left']
  player_world_x += 5 if keys['right']

  # Гравітація
  velocity_y += gravity
  player_world_y += velocity_y
  player.y = player_world_y
  on_ground = false

  # Колізія з платформами
  platforms.each do |plat|
    s = plat[:shape]
    if player_world_x + player.size > plat[:original_x] &&
       player_world_x < plat[:original_x] + s.width &&
       player_world_y + player.size > s.y &&
       player_world_y + player.size < s.y + 20 &&
       velocity_y >= 0
      player_world_y = s.y - player.size
      velocity_y = 0
      on_ground = true
    end
  end


# Колізія з перешкодами
platforms.each do |plat|
  s = plat[:shape]
  obstacles.each do |obs|
    o = obs[:shape]
    obstacle_top = o.y
    obstacle_bottom = o.y + o.height
    obstacle_left = obs[:original_x]
    obstacle_right = obs[:original_x] + o.width

    player_right = player_world_x + player.size
    player_bottom = player.y + player.size

    if player_world_x < obstacle_right &&
       player_right > obstacle_left &&
       player.y < obstacle_bottom &&
       player_bottom > obstacle_top

      # Колізія зверху (приземлення на перешкоду)
      if velocity_y > 0 && player_bottom - obstacle_top < 10
        player.y = obstacle_top - player.size
        velocity_y = 0
        on_ground = true

      # Колізія знизу (удар головою)
      elsif velocity_y < 0 && obstacle_bottom - player.y < 10
        player.y = obstacle_bottom
        velocity_y = 1

      # Горизонтальна колізія (вліво або вправо)
      else
        if player_world_x < obstacle_left
          player_world_x = obstacle_left - player.size
        else
          player_world_x = obstacle_right
        end
      end
    end
  end
end



  # Вбивство ворогів при стрибку згори
  enemies.delete_if do |enemy|
    e = enemy[:shape]
    stomped = false

    if player_world_x + player.size > enemy[:original_x] &&
       player_world_x < enemy[:original_x] + e.size &&
       player_world_y + player.size > e.y &&
       player_world_y + player.size < e.y + 20 &&
       velocity_y > 0
      stomped = true
      e.remove
      velocity_y = jump_power / 2  # Відскік
    elsif player_world_x + player.size > enemy[:original_x] &&
          player_world_x < enemy[:original_x] + e.size &&
          player_world_y < e.y + e.size &&
          player_world_y + player.size > e.y
      lives -= 1
      lives_text.text = "Lives: #{lives}"
      if lives <= 0
        game_over = true
        game_over_text.text = "Game Over"
      else
        player_world_x = spawn_x
        player_world_y = spawn_y
        velocity_y = 0
        camera_x = 0
        camera_started = false
        start_time = Time.now
      end
    end

    stomped
  end

  # Падіння вниз
  if player_world_y > 800
    lives -= 1
    lives_text.text = "Lives: #{lives}"
    if lives <= 0
      game_over = true
      game_over_text.text = "Game Over"
    else
      player_world_x = spawn_x
      player_world_y = spawn_y
      velocity_y = 0
      camera_x = 0
      camera_started = false
      start_time = Time.now
    end
  end

  # Колекція монет
  coins.delete_if do |coin|
    c = coin[:shape]
    overlap = (player_world_x < coin[:original_x] + c.size &&
               player_world_x + player.size > coin[:original_x] &&
               player_world_y < c.y + c.size &&
               player_world_y + player.size > c.y)
    if overlap
      score += 1
      score_text.text = "Coins: #{score}/#{total_coins}"
      c.remove
    end
    overlap
  end

  # Вороги рухаються
enemies.each do |enemy|
  plat = enemy[:platform]
  dir = enemy[:direction]
  s = plat[:shape]
  enemy[:original_x] += dir * 2

  # Перевірка колізії з перешкодами
  obstacles.each do |obs|
    o = obs[:shape]
    obstacle_left = obs[:original_x]
    obstacle_right = obs[:original_x] + o.width
    enemy_left = enemy[:original_x]
    enemy_right = enemy[:original_x] + enemy[:shape].size

    # Якщо ворог зіштовхується з перешкодою, змінюємо напрямок
    if enemy_right > obstacle_left && enemy_left < obstacle_right &&
       enemy[:shape].y + enemy[:shape].size > o.y && enemy[:shape].y < o.y + o.height
      enemy[:direction] *= -1
    end
  end

  # Перевірка, чи ворог виходить за межі платформи
  if enemy[:original_x] < plat[:original_x] || enemy[:original_x] > plat[:original_x] + s.width - enemy[:shape].size
    enemy[:direction] *= -1
  end

  # Оновлення позиції ворога
  enemy[:shape].x = enemy[:original_x] - camera_x
end


  # Відображення
  player.x = player_world_x - camera_x
  player.y = player_world_y

  platforms.each { |p| p[:shape].x = p[:original_x] - camera_x }
  obstacles.each { |o| o[:shape].x = o[:original_x] - camera_x }
  coins.each    { |c| c[:shape].x = c[:original_x] - camera_x }
  goal[:shape].x = goal[:original_x] - camera_x

  # Перевірка досягнення фінішу
  if player_world_x + player.size >= goal[:original_x]
      game_over = true
      game_over_text.text = "You win! Coins: #{score}/#{total_coins}"
    camera_started = false
  end
end

show