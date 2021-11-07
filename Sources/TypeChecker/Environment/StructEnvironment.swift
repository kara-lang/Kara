//
//  Created by Max Desiatov on 07/11/2021.
//

import Syntax

@dynamicMemberLookup
struct StructEnvironment<A: Annotation> {
  init(members: MemberEnvironment<A> = .init()) {
    self.members = members
  }

  let members: MemberEnvironment<A>

  public subscript<T>(dynamicMember keyPath: KeyPath<MemberEnvironment<A>, T>) -> T {
    members[keyPath: keyPath]
  }
}
