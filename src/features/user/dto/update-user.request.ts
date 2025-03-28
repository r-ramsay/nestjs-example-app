import { IsEnum, IsOptional, IsString } from 'class-validator';
import { Language as AppLanguage } from '../../../core/enums/language.enum';

export class UpdateUserRequest {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(AppLanguage)
  language?: AppLanguage;
}
