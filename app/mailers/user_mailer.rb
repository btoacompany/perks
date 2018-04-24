class UserMailer < ApplicationMailer
  default from: "support.prizy@btoa-company.com"

  def verify_account(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】#{@user[:company_owner]}さんから招待が届きました。")
  end

  def reward_approved_email(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】ポイントの交換が承認されました！")
  end

  def receive_points_email(data)
    @user = data 
    if @user[:nickname_id] == 0
      mail(to: @user[:email], subject: "【プライジー♪】#{@user[:sender]}さんより感謝のメッセージが届いています")
    else
      mail(to: @user[:email], subject: "【プライジー♪】#{$nicknames[@user[:nickname_id]]}さんより感謝のメッセージが届いています")
    end
  end

  def reset_password(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】パスワードの再設定")
  end

  def invite_welcome_email(data)
    @user = data 
    mail(to: @user[:email], subject: "【Prizy】ご登録ありがとうございます")
  end

  def redeem_prizy_reward(data)
    @user = data
    mail(to: "info@btoa-company.com", subject: "【Prizy】Redeem Reward")
  end

  def test_mail
    mail(to: "naoto.udagawa1230@gmail.com", subject: "【Prizy】テストが終わりました")
  end
  
  def receive_comments_email(data)
    @user = data 
    mail(to: @user[:email], subject: "【プライジー♪】あなたのメッセージに返信がきました")
  end

  def receive_likes_email(data)
    @user = data 
    mail(to: @user[:email], subject: "【プライジー♪】あなたの投稿に『ありがとう』のスタンプがつきました")
  end

  def comment_on_comment_email(data)
    @user = data 
    mail(to: @user[:email], subject: "【プライジー♪】あなたのコメントに返信がきました")
  end
end
