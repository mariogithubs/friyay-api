#### Description
- the vote_scope for our "Likes" is `vote_scope: :like`
- This means that we can have other votes_scopes
  + For instance, we could leave blank and have votes with scores

<table>
  <thead>
    <tr>
      <th>Code</th>
      <th>Meaning</th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <p>tip.liked_by user, vote_scope: :like</p>
      </td>
      <td>Registers a "Like" for the Tip by the user</td>
      <td></td>
    </tr>
    <tr>
      <td>tip.unliked_by user, vote_scope: :like</td>
      <td>Removes a "Like" for the Tip by the user</td>
      <td></td>
    </tr>
    <tr>
      <td>tip.disliked_by user, vote_scope: :like</td>
      <td>Registers a "Dislike" vote for Tip by user</td>
      <td></td>
    </tr>
    <tr>
      <td>tip.undisliked_by user, vote_scope: :like</td>
      <td>Removes a "Dislike" vote for Tip by user</td>
      <td>weird name</td>
    </tr>
  </tbody>
</table>