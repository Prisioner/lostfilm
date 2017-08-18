require 'sqlite3'

class DBElement
  attr_reader :row_id

  # ����室��� ��८�।�����
  TABLE = nil

  # ���࠭�� ���� � �� � ��६����� �����
  # ��⮢�� �� � ࠡ�� - ᮧ���� ���������騥 ⠡����
  def self.prepare_db!(db_path)
    ## ���࠭塞 ���� � ��
    @@db_path = db_path
    # ������⨬��
    db = SQLite3::Database.open(@@db_path)
    # ������ ⠡���� ��� �ਠ���, �᫨ �� ��� � ��
    db.execute(
      <<~SERIES_TABLE
        CREATE TABLE IF NOT EXISTS "main"."series" (
          "id" INTEGER NOT NULL UNIQUE,
          "title" TEXT,
          "title_orig" TEXT,
          "link" TEXT,
          "favorited" INTEGER,
          "followed" INTEGER
        )
      SERIES_TABLE
    )
    # ������ ⠡���� ��� ������, �᫨ �� ��� � ��
    db.execute(
      <<~EPISODES_TABLE
        CREATE TABLE IF NOT EXISTS "main"."episodes" (
          "id" TEXT NOT NULL UNIQUE,
          "series_id" INTEGER,
          "watched" INTEGER,
          "downloaded" INTEGER
        )
      EPISODES_TABLE
    )
    # �⪫�砥���
    db.close
  end

  def initialize(row_id: nil)
    @row_id = row_id
  end

  def exists?
    !@row_id.nil?
  end
end
