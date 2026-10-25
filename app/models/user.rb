class User < ApplicationRecord
  has_many :commitments, dependent: :destroy
  has_many :check_ins, through: :commitments
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
