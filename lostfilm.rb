# encoding: utf-8
# Этот код необходим только при использовании русских букв на Windows
if Gem.win_platform?
  Encoding.default_external = Encoding.find(Encoding.locale_charmap)
  Encoding.default_internal = __ENCODING__

  [STDIN, STDOUT].each do |io|
    io.set_encoding(Encoding.default_external, Encoding.default_internal)
  end
end

require_relative 'lib/lostfilm_client'
require 'optparse'

# Загружаем конфиг
config = ConfigLoader.new
# Подключаем БД
DBElement.prepare_db!(config.db_path)

# Задаём опцию по умолчанию
options = {act: :get_new_episodes}

optparser = OptionParser.new do |opt|
  opt.banner = 'Использование: ruby lostfilm.rb [options]'

  opt.on('-h', '--help', 'Выводит эту справку') do
    puts opt
    exit
  end

  opt.on('--login', 'Запускает процесс авторизации') { options[:act] = :login }

  opt.on('-s [TYPE]', '--get-series-list [TYPE]', 'Загружает список сериалов',
                                                  'all (по умолчанию) - всех сериалов',
                                                  'fav - только избранных') do |o|
    options[:act] = :get_series_list
    options[:type] = o.nil? ? :all : o.to_sym
  end

  opt.on('-f ID,ID,ID', '--follow ID,ID,ID', Array,
         'Добавляет сериал(ы) в список отслеживаемых') do |o|
    options[:act] = :follow
    options[:list] = o.map(&:to_i)
  end

  opt.on('-u ID,ID,ID', '--unfollow ID,ID,ID', Array,
         'Убирает сериал(ы) из списка отслеживаемых') do |o|
    options[:act] = :unfollow
    options[:list] = o.map(&:to_i)
  end

  opt.on('-e', '--get-new-episodes',
         'Загружает список новых эпизодов (действие по умолчанию)') do
    options[:act] = :get_new_episodes
  end

  opt.on('-l [TYPE]', '--list [TYPE]', 'Выводит список сериалов',
                                       'all - всех',
                                       'fav - избранных',
                                       'followed (по умолчанию) - отслеживаемых') do |o|
    options[:act] = :show_list
    options[:type] = o.nil? ? :followed : o.to_sym
  end
end

# Если передан некорректный ключ - выводим справку
begin
  optparser.parse!
rescue OptionParser::InvalidOption
  puts "Параметры не распознаны"
  optparser.parse!(['-h'])
end

case options[:act]
# Аторизация
when :login
  begin
    config.session = LostFilmClient.auth
  rescue LostFilmAPI::AuthorizationError
    # Сбрасываем старую сессию при неудачной авторизации
    # (если вдруг сессия была установлена)
    config.session = ''
    config.save!
    puts "Введён неверный логин или пароль."
    exit
  end

# Загрузка списка сериалов
when :get_series_list
  begin
    LostFilmClient.get_series_list(type: options[:type], config: config)
  rescue LostFilmAPI::NotAuthorizedError
    puts "Необходимо пройти авторизацию! 'ruby lostfilm.rb --login'"
    exit
  end

# Изменяем статус "отслеживается" для сериалов
when :follow, :unfollow
  LostFilmClient.change_follow_status(
    list: options[:list],
    act: options[:act],
    original_titles: config.original_titles
  )

# Скачиваем торрент-файлы для новых эпизодов
# Вывод по умолчанию
when :get_new_episodes
  begin
    LostFilmClient.get_new_episodes(config: config)
  rescue LostFilmAPI::NotAuthorizedError
    puts "Необходимо пройти авторизацию! 'ruby lostfilm.rb --login'"
    exit
  end

# Вывод списка сериалов
when :show_list
  LostFilmClient.show_list(type: options[:type], original_titles: config.original_titles)

# Неизвестные параметры, если сюда вообще возможно попасть?
else
  puts "Команда не распознана. 'ruby lostfilm.rb --help' для вывода справки"
end

# Сохраняем конфиг перед завершением работы
config.save!
