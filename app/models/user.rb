class User < ApplicationRecord
  has_many :messages
  has_many :requests
  has_many :rides, through: :requests
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
end
